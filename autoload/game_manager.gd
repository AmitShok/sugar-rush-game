extends Node
signal changed
signal round_started
signal shop_opened
signal run_ended(won: bool)
signal toast(message: String)
# Sound-effect events for SoundBoard (v0.31): "coin", "sell", "reroll", "pack_open", ...
signal sfx(name: String)
@export var config: RunConfig = preload("res://resources/default_run.tres")
var jokers: JokerManager
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var run_seed: int = 0
var round_index: int = 0
var score: int = 0
var moves: int = 0
var gummies: int = 0
var streak: int = 0
var poison: int = -1
var poison_cleared: bool = false
var state: String = "menu"
var last_chips: float = 0
var last_mult: float = 1
var last_award: int = 0
var last_summary: String = ""
var motion: bool = true
var sound: bool = true
var music: bool = true
var crt_enabled: bool = true
var master_volume: float = 0.8
var preferences_path: String = "user://preferences.cfg"
var audio_rng: RandomNumberGenerator = RandomNumberGenerator.new()
const SHAKER_CAPACITY: int = 2
var hints_used: int = 0
var consumables: Array[String] = []
# Compatibility for the original Shaker API; all items share the same capacity.
var shakers: int:
 get: return consumables.count("sugar_shaker")
 set(value):
  while "sugar_shaker" in consumables: consumables.erase("sugar_shaker")
  for i: int in range(mini(maxi(value,0),SHAKER_CAPACITY-consumables.size())): consumables.append("sugar_shaker")
var consumable_offers: Array[String] = []
var offers: Array[JokerData] = []
var reroll_cost: int = 3
var candy_levels: Array[int] = []
var candy_bonuses: Array[int] = []
# Recipe (match type) levels for this run; see RecipeCatalog.
var recipe_levels: Dictionary = RecipeCatalog.default_levels()
var last_recipe: String = ""
# Economy and skip Tags (v0.20).
var last_interest: int = 0
var tags_claimed: Array[String] = []
var free_jokers: int = 0 # pending Handout Tags for the next shop
var free_offer_id: String = "" # the Joker offer that is currently free
var free_rerolls: int = 0
var free_owned: Array[String] = [] # Jokers taken with a Handout Tag sell for $0
var offer_editions: Dictionary = {} # shop offer Joker id -> edition (v0.21)
var offer_rolls: int = 0 # shop restocks this run; keys edition rolls
var bonus_moves: int = 0 # pending Extra Moves Tags for the next round
var bonus_moves_used: int = 0 # extra moves added to the current round
var shop_closed: bool = false # true after a skip: no shopping until the next real shop
func hint_cost() -> int:
 return 1+hints_used
func _ready() -> void:
 jokers = preload("res://scenes/JokerManager.tscn").instantiate() as JokerManager
 jokers.name = "JokerManager"
 add_child(jokers)
 jokers.capacity = config.joker_slots
 ScoreEngine.configure(config)
 audio_rng.randomize()
 load_preferences()
func load_preferences() -> void:
 var prefs: ConfigFile = ConfigFile.new()
 if prefs.load(preferences_path) == OK:
  motion = prefs.get_value("settings","motion",true)
  sound = prefs.get_value("settings","sound",true)
  music = prefs.get_value("settings","music",true)
  crt_enabled = prefs.get_value("settings","crt_enabled",true)
  master_volume = clampf(float(prefs.get_value("settings","master_volume",0.8)),0.0,1.0)
 apply_audio_settings()
func apply_audio_settings() -> void:
 AudioServer.set_bus_volume_db(0,linear_to_db(maxf(master_volume,0.0001)))
 AudioServer.set_bus_mute(0,not sound or master_volume<=0.0)
func next_sound_pitch(cascade: int) -> float:
 return clampf((1.0+cascade*0.12)*audio_rng.randf_range(0.90,1.10),0.8,2.2)
func save_preferences() -> void:
 var prefs: ConfigFile = ConfigFile.new()
 prefs.set_value("settings","motion",motion)
 prefs.set_value("settings","sound",sound)
 prefs.set_value("settings","music",music)
 prefs.set_value("settings","crt_enabled",crt_enabled)
 prefs.set_value("settings","master_volume",master_volume)
 apply_audio_settings()
 var error: Error=prefs.save(preferences_path)
 if error != OK: push_warning("Could not save settings: "+error_string(error))
func joker_title(item: JokerData, offered: bool = false) -> String:
 var edition: String = offer_editions.get(item.id,"") if offered else jokers.edition(item.id)
 return item.display_name+(" (%s)" % EditionCatalog.ITEMS[edition].name if not edition.is_empty() else "")
# Description with live scaling and edition details (owned Jokers) or the offer edition.
func joker_text(item: JokerData, offered: bool = false) -> String:
 var text: String = joker_description(item)
 var growth: String = scaling_status(item.id)
 if not growth.is_empty() and not offered: text += "
"+growth
 var edition: String = offer_editions.get(item.id,"") if offered else jokers.edition(item.id)
 if not edition.is_empty(): text += "
"+EditionCatalog.label(edition)
 return text
func scaling_status(id: String) -> String:
 match id:
  "sugar_cube": return "Now: +%s Mult" % int(jokers.counter(id))
  "gumball_jar": return "Now: +%s Candys" % int(jokers.counter(id))
  "candy_cane": return "Now: x%s Mult" % snappedf(1.0+jokers.counter(id),0.1)
 return ""
func joker_description(item: JokerData) -> String:
 if item.id != "roulette": return item.description
 if not jokers.has("roulette") or poison < 0:
  return item.description+"\nA random candy type is picked at the start of each round."
 var status: String="Matched: penalty avoided. x2 Mult stays active." if poison_cleared else "Not matched yet: match this type or lose half your round score."
 return "This round: %s\nMatches of this type get x2 Mult.\n%s\nThe wheel marks every candy of this type. Blast collateral does not count." % [config.candies[poison].display_name,status]
func candy_level(color: int) -> int:
 return candy_levels[color] if color >= 0 and color < candy_levels.size() else 0
func candy_bonus(color: int) -> int:
 return candy_bonuses[color] if color >= 0 and color < candy_bonuses.size() else 0
func candy_value(color: int) -> int:
 return config.candies[color].base_chips+candy_bonus(color)
func upgrade_gain(color: int) -> int:
 return ceili(config.candies[color].base_chips*0.5)
# Candy upgrades come only from Candy Packs (v0.28); there is no direct purchase.
func level_candy(color: int) -> bool:
 if color < 0 or color >= config.candies.size(): return false
 candy_levels[color] += 1
 candy_bonuses[color] += upgrade_gain(color)
 return true
func recipe_level(id: String) -> int:
 return RecipeCatalog.level(recipe_levels,id)
func level_recipe(id: String, amount: int = 1) -> void:
 if RecipeCatalog.ITEMS.has(id): recipe_levels[id] = recipe_level(id)+amount
# Booster packs (v0.23). Recipe levels come from Recipe Packs, the Cookbook Tag and Cookbook Blast.
var pack_offers: Array = [] # two shop pack slots: {"kind","jumbo","free"}
var opened_pack: Dictionary = {} # the pack being opened: {"kind","jumbo","choices","picks"}
var free_packs: int = 0 # pending Pack Tags
var interest_halved: bool = false # Golden Batch
func roll_packs() -> void:
 pack_offers.clear()
 for slot: int in range(2): pack_offers.append(PackCatalog.roll([run_seed,round_index,slot,"pack"]))
 if free_packs > 0 and not pack_offers.is_empty():
  pack_offers[0]["jumbo"] = pack_offers[0].kind != "rush"
  pack_offers[0]["free"] = true
  free_packs -= 1
func pack_rng(salt: Variant) -> RandomNumberGenerator:
 var pack_random: RandomNumberGenerator = RandomNumberGenerator.new()
 pack_random.seed = hash([run_seed,round_index,offer_rolls,salt])
 return pack_random
func can_open_pack(slot: int) -> bool:
 return state == "shop" and not shop_closed and opened_pack.is_empty() and slot >= 0 and slot < pack_offers.size() and gummies >= PackCatalog.price(pack_offers[slot])
func open_pack(slot: int) -> bool:
 if not can_open_pack(slot): return false
 var pack: Dictionary = pack_offers[slot]
 gummies -= PackCatalog.price(pack)
 pack_offers.remove_at(slot)
 opened_pack = {"kind":pack.kind,"jumbo":pack.jumbo,"choices":pack_choices(pack,pack_rng(["open",slot,pack.kind])),"picks":PackCatalog.picks(pack)}
 sfx.emit("pack_open")
 changed.emit()
 return true
func pack_choices(pack: Dictionary, pack_random: RandomNumberGenerator) -> Array:
 var pool: Array = []
 match String(pack.kind):
  "joker":
   for item: JokerData in config.jokers:
    if not jokers.has(item.id) and item not in offers: pool.append(item.id)
  "recipe":
   for id: String in RecipeCatalog.ORDER:
    if id != "diagonal" or jokers.has("kaleidoscope"): pool.append(id)
  "candy": pool = range(config.candies.size())
  "treat": pool = ConsumableCatalog.ITEMS.keys()
  "rush":
   for id: String in PackCatalog.RUSH:
    if id == "big_spoon" and jokers.capacity >= PackCatalog.MAX_JOKER_SLOTS: continue
    if id == "meltdown" and jokers.equipped.size() < 2: continue
    if id == "glitter" and not has_plain_joker(): continue
    pool.append(id)
 var choices: Array = []
 for i: int in range(mini(PackCatalog.size(pack),pool.size())):
  # Joker packs follow rarity odds (JokerRarity); other packs pick evenly.
  var index: int = JokerRarity.pick_index(pool,pack_random,joker_by_id) if pack.kind == "joker" else pack_random.randi_range(0,pool.size()-1)
  var value: Variant = pool.pop_at(index)
  var choice: Dictionary = {"type":pack.kind,"id":value}
  if pack.kind == "joker": choice["edition"] = EditionCatalog.roll([run_seed,offer_rolls,"pack",value])
  choices.append(choice)
 return choices
func has_plain_joker() -> bool:
 for item: JokerData in jokers.equipped:
  if jokers.edition(item.id).is_empty(): return true
 return false
func joker_by_id(id: String) -> JokerData:
 for item: JokerData in config.jokers:
  if item.id == id: return item
 return null
# Why a pack card cannot be taken right now ("" when it can).
func pack_block_reason(choice: Dictionary) -> String:
 match String(choice.type):
  "joker":
   if jokers.equipped.size() >= jokers.capacity: return "No Joker slots left."
  "treat":
   if consumables.size() >= SHAKER_CAPACITY: return "Your items are full."
 return ""
func take_pack_card(index: int) -> bool:
 if opened_pack.is_empty() or index < 0 or index >= opened_pack.choices.size(): return false
 var choice: Dictionary = opened_pack.choices[index]
 if not pack_block_reason(choice).is_empty(): return false
 match String(choice.type):
  "joker": jokers.add(joker_by_id(String(choice.id)),String(choice.get("edition","")))
  "recipe": level_recipe(String(choice.id))
  "candy": level_candy(int(choice.id))
  "treat": consumables.append(String(choice.id))
  "rush": apply_rush(String(choice.id))
 opened_pack.choices.remove_at(index)
 opened_pack.picks = int(opened_pack.picks)-1
 if int(opened_pack.picks) <= 0 or opened_pack.choices.is_empty(): opened_pack = {}
 sfx.emit("card_take")
 changed.emit()
 return true
func skip_pack() -> void:
 if opened_pack.is_empty(): return
 opened_pack = {}
 changed.emit()
func apply_rush(id: String) -> void:
 var rush_random: RandomNumberGenerator = pack_rng(["rush",id])
 match id:
  "glitter":
   var plain: Array[JokerData] = []
   for item: JokerData in jokers.equipped:
    if jokers.edition(item.id).is_empty(): plain.append(item)
   if not plain.is_empty():
    var target: JokerData = plain[rush_random.randi_range(0,plain.size()-1)]
    jokers.editions[target.id] = EditionCatalog.ORDER[rush_random.randi_range(0,EditionCatalog.ORDER.size()-1)]
  "cookbook_blast":
   for recipe: String in RecipeCatalog.ORDER: level_recipe(recipe)
  "big_spoon":
   jokers.capacity = mini(PackCatalog.MAX_JOKER_SLOTS,jokers.capacity+1)
   gummies = maxi(0,gummies-PackCatalog.BIG_SPOON_COST)
  "meltdown":
   if jokers.equipped.size() >= 2:
    var victim: JokerData = jokers.equipped[rush_random.randi_range(0,jokers.equipped.size()-1)]
    free_owned.erase(victim.id)
    jokers.remove(victim)
    var lucky: JokerData = jokers.equipped[rush_random.randi_range(0,jokers.equipped.size()-1)]
    jokers.editions[lucky.id] = "poly"
  "golden_batch":
   gummies += PackCatalog.GOLDEN_BATCH_CASH
   interest_halved = true
# Bosses (v0.22): one per ante, drawn from the run seed.
var boss_cache_seed: int = -1
var boss_cache: Array[String] = []
func boss_for(ante: int) -> String:
 if boss_cache_seed != run_seed or boss_cache.is_empty():
  boss_cache = BossCatalog.for_run(run_seed)
  boss_cache_seed = run_seed
 return boss_cache[clampi(ante,0,boss_cache.size()-1)]
func curse_for(index: int) -> String:
 return boss_for(index/3) if index%3 == 2 else "none"
func curse() -> String:
 return curse_for(round_index)
func round_name(index: int) -> String:
 return BossCatalog.ITEMS[curse_for(index)].name if index%3 == 2 else config.rounds[index].display_name
func round_description(index: int) -> String:
 return BossCatalog.ITEMS[curse_for(index)].description if index%3 == 2 else config.rounds[index].description
func current_round() -> RoundData:
 return config.rounds[round_index]
func start_run(seed_value: int = 0) -> void:
 run_seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
 rng.seed = run_seed
 round_index = 0
 gummies = config.starting_gummies
 hints_used = 0
 jokers.clear_all()
 offer_editions.clear()
 offer_rolls = 0
 pack_offers.clear()
 opened_pack = {}
 free_packs = 0
 interest_halved = false
 jokers.capacity = config.joker_slots
 consumables.clear()
 consumable_offers.clear()
 offers.clear()
 candy_levels.resize(config.candies.size())
 candy_levels.fill(0)
 candy_bonuses.resize(config.candies.size())
 candy_bonuses.fill(0)
 recipe_levels = RecipeCatalog.default_levels()
 last_interest = 0
 tags_claimed.clear()
 free_owned.clear()
 shop_closed = false
 free_jokers = 0
 free_offer_id = ""
 free_rerolls = 0
 bonus_moves = 0
 bonus_moves_used = 0
 last_recipe = ""
 start_round()
func start_round() -> void:
 score = 0
 streak = 0
 moves = current_round().moves+bonus_moves
 if curse() == "hurry": moves = maxi(1,moves-BossCatalog.HURRY_MOVES)
 bonus_moves_used = bonus_moves
 shop_closed = false
 bonus_moves = 0
 poison = rng.randi_range(0,config.candies.size()-1) if jokers.has("roulette") else -1
 poison_cleared = false
 last_chips = 0
 last_mult = 1
 last_recipe = ""
 state = "playing"
 round_started.emit()
 changed.emit()
func begin_move(valid: bool) -> void:
 moves -= 1
 streak = streak+1 if valid else 0
 if curse() == "tax" and gummies > 0: gummies -= BossCatalog.TAX
 changed.emit()
func award(result: Dictionary, color: int) -> void:
 score += int(result.total)
 last_chips = result.chips
 last_mult = result.mult
 last_recipe = String(result.get("recipe",""))
 if color == poison: poison_cleared = true
 # Scaling Jokers grow from what you score.
 if String(result.get("recipe","")) in ["quint","shape"]: jokers.grow("sugar_cube",1.0)
 jokers.grow("candy_cane",0.1*int(result.get("fired",0)))
 changed.emit()
func finish_move() -> void:
 var adjusted: int = score/2 if poison >= 0 and not poison_cleared else score
 if adjusted >= current_round().quota or moves <= 0: settle_round()
func settle_round() -> void:
 var penalty: int = 0
 if poison >= 0 and not poison_cleared:
  penalty = score-score/2
  score -= penalty
 if score < current_round().quota:
  state = "over"
  run_ended.emit(false)
 else:
  var reward: int = round_reward()
  var move_bonus: int = mini(config.move_bonus_cap,maxi(0,moves)/maxi(1,config.moves_per_bonus))
  # Interest is earned on the cash you held when the round ended, before the payout.
  last_interest = interest()
  last_award = reward+move_bonus+last_interest
  gummies += last_award
  jokers.grow("gumball_jar",8.0)
  last_summary = "Round $%s + saved moves $%s + interest $%s = $%s" % [reward,move_bonus,last_interest,last_award]
  if round_index == config.rounds.size()-1:
   state = "over"
   run_ended.emit(true)
  else:
   state = "shop"
   shop_closed = false
   reroll_cost = config.base_reroll_cost
   roll_packs()
   opened_pack = {}
   roll_offers()
   shop_opened.emit()
 changed.emit()
func interest() -> int:
 var cap: int = config.interest_cap/2 if interest_halved else config.interest_cap
 return mini(cap,maxi(0,gummies)/maxi(1,config.interest_per))
func tag_for(index: int) -> String:
 return TagCatalog.for_round(run_seed,index)
# The round a skip would pass over: the next one from the shop, or a fresh, untouched round in play.
func skip_target() -> int:
 if state == "shop": return round_index+1
 if state == "playing" and score == 0 and moves == current_round().moves+bonus_moves_used and streak == 0: return round_index
 return -1
func can_skip() -> bool:
 var target: int = skip_target()
 return target >= 0 and target < config.rounds.size() and TagCatalog.skippable(target)
# Skipping forgoes the round's cash and its shop, claims the round's Tag, and leaves you choosing the next round.
func skip_round() -> String:
 if not can_skip(): return ""
 round_index = skip_target()
 # Extra moves granted to an untouched round carry over to the next one.
 if state == "playing": bonus_moves += bonus_moves_used
 var tag: String = tag_for(round_index)
 apply_tag(tag)
 bonus_moves_used = 0
 shop_closed = true
 pack_offers.clear()
 opened_pack = {}
 state = "shop"
 offers.clear()
 consumable_offers.clear()
 free_offer_id = ""
 offer_editions.clear()
 last_award = 0
 last_interest = 0
 last_summary = "Skipped %s: claimed %s" % [round_name(round_index),TagCatalog.ITEMS[tag].name]
 tags_claimed.append(tag)
 shop_opened.emit()
 changed.emit()
 return tag
func apply_tag(tag: String) -> void:
 var tag_rng: RandomNumberGenerator = RandomNumberGenerator.new()
 tag_rng.seed = hash([run_seed,round_index,"tag_effect"])
 match tag:
  "piggy": gummies += mini(maxi(gummies,0),TagCatalog.PIGGY_CAP)
  "handout": free_jokers += 1
  "cookbook":
   var pool: Array[String] = ["trio","quad","quint","shape"]
   for i: int in range(2):
    var id: String = pool.pop_at(tag_rng.randi_range(0,pool.size()-1))
    level_recipe(id)
  "reroll": free_rerolls += TagCatalog.FREE_REROLLS
  "sweets":
   if consumables.size() < SHAKER_CAPACITY:
    var keys: Array = ConsumableCatalog.ITEMS.keys()
    consumables.append(keys[tag_rng.randi_range(0,keys.size()-1)])
   else: gummies += TagCatalog.SWEETS_FALLBACK_CASH
  "moves": bonus_moves += TagCatalog.EXTRA_MOVES
  "pack": free_packs += 1
func sell_value(item: JokerData) -> int:
 return 0 if item.id in free_owned else (item.price+EditionCatalog.price_bonus(jokers.edition(item.id)))/2
func offer_price(item: JokerData) -> int:
 return 0 if item.id == free_offer_id else item.price+EditionCatalog.price_bonus(offer_editions.get(item.id,""))
func current_reroll_cost() -> int:
 return 0 if free_rerolls > 0 else reroll_cost
func round_reward() -> int:
 match round_index % 3:
  1: return config.big_reward
  2: return config.boss_reward
 return config.clear_reward
func roll_offers() -> void:
 consumable_offers.clear()
 var card_pool: Array=ConsumableCatalog.ITEMS.keys()
 for slot: int in range(2):
  var pick: int=rng.randi_range(0,card_pool.size()-1)
  consumable_offers.append(card_pool.pop_at(pick))
 offers.clear()
 var pool: Array[JokerData] = []
 for item: JokerData in config.jokers:
  if not jokers.has(item.id): pool.append(item)
 while offers.size() < 4 and not pool.is_empty():
  # Rarer, stronger Jokers show up less often (JokerRarity.WEIGHTS).
  var i: int = JokerRarity.pick_index(pool,rng)
  offers.append(pool[i])
  pool.remove_at(i)
 free_offer_id = ""
 if free_jokers > 0 and not offers.is_empty():
  free_offer_id = offers[0].id
  free_jokers -= 1
 offer_rolls += 1
 offer_editions.clear()
 for slot: int in range(offers.size()):
  var edition: String = EditionCatalog.roll([run_seed,offer_rolls,slot,offers[slot].id])
  if not edition.is_empty(): offer_editions[offers[slot].id] = edition
func buy_shaker() -> bool:
 return buy_consumable("sugar_shaker")
func buy_consumable(id: String) -> bool:
 if state != "shop" or shop_closed or id not in consumable_offers or consumables.size()>=SHAKER_CAPACITY: return false
 var price: int=ConsumableCatalog.ITEMS[id].price
 if gummies<price: return false
 gummies-=price
 consumables.append(id)
 consumable_offers.erase(id)
 sfx.emit("coin")
 changed.emit()
 return true
func consume_item(id: String) -> bool:
 if state != "playing" or id not in consumables: return false
 consumables.erase(id)
 sfx.emit("use_item")
 changed.emit()
 return true
func discard_consumable(index: int) -> void:
 if state != "shop" or index<0 or index>=consumables.size(): return
 consumables.remove_at(index)
 changed.emit()
func buy(item: JokerData) -> bool:
 var price: int = offer_price(item)
 if state != "shop" or shop_closed or item not in offers or gummies < price or not jokers.can_add(item): return false
 gummies -= price
 if item.id == free_offer_id:
  free_offer_id = ""
  free_owned.append(item.id)
 jokers.add(item,String(offer_editions.get(item.id,"")))
 offer_editions.erase(item.id)
 offers.erase(item)
 sfx.emit("coin")
 changed.emit()
 return true
func move_joker(item: JokerData, delta: int) -> bool:
 if state != "shop" or shop_closed: return false
 if not jokers.move(item,delta): return false
 changed.emit()
 return true
func sell(item: JokerData) -> void:
 if state != "shop" or item not in jokers.equipped: return
 gummies += sell_value(item)
 free_owned.erase(item.id)
 jokers.remove(item)
 sfx.emit("sell")
 changed.emit()
func reroll() -> void:
 var cost: int = current_reroll_cost()
 if state != "shop" or shop_closed or gummies < cost: return
 gummies -= cost
 if free_rerolls > 0: free_rerolls -= 1
 else: reroll_cost += config.reroll_increment
 roll_offers()
 sfx.emit("reroll")
 changed.emit()
func next_round() -> void:
 if state != "shop": return
 round_index += 1
 start_round()
