extends Node
# Full-run simulator (v0.35). A bot plays complete runs from $4 through all 18 rounds using the
# REAL GameManager (shop rolls, rarity odds, prices, packs, editions, interest, rewards, bosses,
# Jelly objective) and a BoardModel set up exactly like GameBoard.start_round.
#
# Run:  Godot --headless --audio-driver Dummy --path . res://tools/RunSim.tscn -- --test runs=20 seed=1000
# Each run prints one line: RUN seed result round reached, build, levels and score/quota per round.
#
# The bot is deliberately ordinary: it plays the best previewed move (plus jelly/roulette goals),
# never skips rounds for Tags and never buys or uses items, so its win rate is a floor for a
# careful human player rather than a ceiling.
const STARTING_BLOCKERS: Array[int] = [18,45] # GameBoard.starting_blockers
# Rough worth of each Joker on its own (from balance_sim solo=1 multipliers), used to shop.
const VALUE: Dictionary = {
 "paintball":10.0,"kaleidoscope":8.0,"addict":7.0,"pop_rock":6.0,"sweet_tooth":5.5,"labyrinth":5.0,
 "midas":5.0,"nuclear":4.5,"striper":4.0,"golden_trio":4.0,"ricochet":3.5,"candy_cane":3.5,
 "wrapper":3.2,"mobius":3.0,"gravity":3.0,"ouroboros":3.0,"sugar_cube":3.0,"gumball_jar":2.5,
 "prism":2.5,"bomb_maker":2.5,"tsquare":2.5,"three_scoops":2.0,"necro":2.0,"roulette":2.0,
 "sledgehammer":1.5,"broken":0.3,
 "supply_berry":1.2,"supply_lemon":1.2,"supply_mint":1.3,"supply_peppermint":1.3,"supply_plum":1.4,"supply_caramel":1.5,
}
const EDITION_VALUE: Dictionary = {"":0.0,"foil":1.0,"holo":1.5,"poly":3.0}
var gm: Node
var runs: int = 10
var seed_base: int = 1000
var verbose: bool = false
var recipe_counts: Dictionary = {}
var round_log: PackedStringArray = []

func _ready() -> void:
 gm = get_node("/root/GameManager")
 for a: String in OS.get_cmdline_user_args():
  if a.begins_with("runs="): runs = int(a.substr(5))
  if a.begins_with("seed="): seed_base = int(a.substr(5))
  if a == "verbose": verbose = true
 gm.sound = false
 gm.music = false
 gm.motion = false
 call_deferred("simulate")

func simulate() -> void:
 var wins: int = 0
 var deaths: Dictionary = {}
 for r: int in range(runs):
  var seed_value: int = seed_base+r*101
  var outcome: Dictionary = play_run(seed_value)
  if outcome.won: wins += 1
  else: deaths[int(outcome.round)] = int(deaths.get(int(outcome.round),0))+1
  print("RUN %d %s round=%d boss=%s jokers=%s levels=%s | %s" % [seed_value,"WIN " if outcome.won else "LOSS",int(outcome.round),outcome.boss,outcome.jokers,outcome.levels," ".join(round_log)])
 print("SUMMARY runs=%d wins=%d deaths=%s" % [runs,wins,deaths])
 get_tree().quit()

func play_run(seed_value: int) -> Dictionary:
 recipe_counts.clear()
 round_log.clear()
 gm.start_run(seed_value)
 while true:
  var quota: int = gm.current_round().quota
  play_round()
  var ratio: float = float(gm.score)/maxf(1.0,float(quota))
  round_log.append("%d:%.2f%s" % [gm.round_index,ratio,"J%d" % gm.jelly_left if gm.curse() == "jelly" else ""])
  if gm.state == "over":
   var won: bool = gm.round_index == gm.config.rounds.size()-1 and gm.score >= quota and gm.objectives_met()
   return {"won":won,"round":gm.round_index,"boss":gm.curse(),"jokers":build_text(),"levels":levels_text()}
  if gm.state == "shop":
   shop()
   gm.next_round()
 return {}

# --- One round on a real BoardModel, mirroring GameBoard ---
func play_round() -> void:
 var model: BoardModel = BoardModel.new()
 model.setup(gm.config,gm.jokers,gm.run_seed+gm.round_index*7919)
 model.locked_color = model.rng.randi_range(0,gm.config.candies.size()-1) if gm.curse() == "inspector" else -1
 model.candy_bonuses = gm.candy_bonuses
 model.fill_fresh()
 for i: int in STARTING_BLOCKERS:
  if i >= 0 and i < model.cells.size(): model.cells[i].blocker = 2
 model.jelly_count = BossCatalog.jelly_count(gm.round_index/3)
 model.setup_boss(gm.curse())
 if model.legal_moves().is_empty(): model.reshuffle()
 gm.jelly_left = model.jelly.size()
 while gm.state == "playing":
  var pick: Vector2i = choose_move(model)
  if pick.x < 0:
   model.reshuffle()
   continue
  var final_move: bool = gm.moves == 1
  var population: int = 0
  for cell: CandyState in model.cells:
   if cell.blocker == 0: population += 1
  model.chocolate_broken = 0
  model.swap(pick.x,pick.y)
  var groups: Array[Dictionary] = model.swap_groups(pick.x,pick.y)
  gm.begin_move(not groups.is_empty())
  if groups.is_empty():
   model.swap(pick.x,pick.y)
  else:
   model.cells[pick.x].age = -1
   model.cells[pick.y].age = -1
   var hand: MoveHand = MoveHand.new()
   var cascade: int = 0
   while not groups.is_empty() and cascade < gm.config.cascade_limit:
    var wave: Dictionary = model.score_wave(groups,cascade,hand,gm.recipe_levels,gm.poison)
    var wilds: Array[int] = []
    var spawns: Array[Dictionary] = []
    for effect: Dictionary in wave.effects:
     if effect.wild >= 0: wilds.append(effect.wild)
     if not effect.spawn.is_empty(): spawns.append(effect.spawn)
    model.remove(wave.removed)
    for spawn: Dictionary in spawns:
     if int(spawn.index) not in wilds: model.place_spawn(spawn)
    for i: int in wilds:
     model.cells[i] = CandyState.new(model.roll_color())
     model.cells[i].coating = 3
    model.refill()
    groups = model.matches()
    cascade += 1
   if cascade >= gm.config.cascade_limit: model.stabilize()
   var result: Dictionary = hand.result(gm.jokers,gm.streak,final_move,population,gm.recipe_levels)
   var recipe: String = String(result.get("recipe",""))
   if recipe != "": recipe_counts[recipe] = int(recipe_counts.get(recipe,0))+1
   gm.award(result,gm.poison if bool(result.get("poisoned",false)) else int(result.get("color",-1)))
  if gm.curse() == "heatwave": model.age_candies([pick.x,pick.y])
  if gm.curse() == "chocolatier": model.spread_chocolate()
  if model.legal_moves().is_empty(): model.reshuffle()
  gm.jelly_left = model.jelly.size()
  gm.finish_move()

# Best previewed move, plus the round's goals: jelly tiles on the Jelly Mould and the Roulette type.
func choose_move(model: BoardModel) -> Vector2i:
 var best: Vector2i = Vector2i(-1,-1)
 var best_value: float = -1.0
 var quota: float = float(gm.current_round().quota)
 var jelly_goal: bool = gm.curse() == "jelly" and not model.jelly.is_empty()
 var tile_value: float = quota/30.0*(50.0 if gm.score >= int(quota) else 1.0)
 var people: int = 0
 for cell: CandyState in model.cells:
  if cell.blocker == 0: people += 1
 for mv: Vector2i in model.legal_moves():
  var preview: Dictionary = model.preview_swap(mv.x,mv.y,gm.recipe_levels,gm.poison)
  if not bool(preview.valid): continue
  var hand: MoveHand = preview.hand
  var result: Dictionary = hand.result(gm.jokers,gm.streak+1,gm.moves == 1,people,gm.recipe_levels)
  var value: float = float(result.total)
  if jelly_goal:
   for i: int in preview.cells:
    if i in model.jelly: value += tile_value
  if gm.poison >= 0 and not gm.poison_cleared and bool(result.get("poisoned",false)): value += quota*0.2
  if value > best_value:
   best_value = value
   best = mv
 return best

# --- Shop policy ---
func worth(item: JokerData, edition: String = "") -> float:
 var value: float = float(VALUE.get(item.id,1.0))+float(EDITION_VALUE.get(edition,0.0))
 # Labyrinth (4+ lines only) switches off every exactly-3 Joker, and vice versa.
 var threes: int = 0
 var has_lab: bool = false
 for owned: JokerData in gm.jokers.equipped:
  if owned == item: continue
  if owned.category == "Three": threes += 1
  if owned.id == "labyrinth": has_lab = true
 if item.id == "labyrinth": value -= 2.5*threes
 if item.category == "Three" and has_lab: value *= 0.15
 return value

func owned_worth(item: JokerData) -> float:
 return worth(item,gm.jokers.edition(item.id))

func weakest_owned() -> JokerData:
 var weakest: JokerData = null
 for item: JokerData in gm.jokers.equipped:
  if weakest == null or owned_worth(item) < owned_worth(weakest): weakest = item
 return weakest

func shop() -> void:
 var rerolls: int = 0
 while true:
  buy_jokers()
  open_packs()
  var slots_free: bool = gm.jokers.equipped.size() < gm.jokers.capacity
  var cost: int = gm.current_reroll_cost()
  # Reroll for Jokers while there is room and spare cash beyond an interest cushion.
  if slots_free and rerolls < 2 and gm.gummies >= cost+8:
   gm.reroll()
   rerolls += 1
   continue
  break

func buy_jokers() -> void:
 var bought: bool = true
 while bought:
  bought = false
  var best: JokerData = null
  var best_value: float = 0.0
  for item: JokerData in gm.offers:
   var value: float = worth(item,String(gm.offer_editions.get(item.id,"")))
   if value > best_value:
    best_value = value
    best = item
  if best == null: return
  # Skip near-worthless Jokers unless the build is empty (a human would wait for better).
  if best_value < (2.0 if not gm.jokers.equipped.is_empty() else 1.2): return
  var price: int = gm.offer_price(best)
  if gm.jokers.equipped.size() >= gm.jokers.capacity:
   var weakest: JokerData = weakest_owned()
   if weakest == null or best_value < owned_worth(weakest)+1.5: return
   if gm.gummies+gm.sell_value(weakest) < price: return
   gm.sell(weakest)
  if gm.gummies >= price and gm.buy(best): bought = true

func pack_priority(pack: Dictionary) -> int:
 match String(pack.kind):
  "joker": return 4 if gm.jokers.equipped.size() < gm.jokers.capacity else 0
  "recipe": return 3
  "rush": return 2
  "candy": return 2
 return 0 # Treat packs: the bot does not use items.

func open_packs() -> void:
 var opened: bool = true
 while opened:
  opened = false
  var best_slot: int = -1
  var best_priority: int = 0
  for slot: int in range(gm.pack_offers.size()):
   var priority: int = pack_priority(gm.pack_offers[slot])
   if priority > best_priority and gm.can_open_pack(slot):
    best_priority = priority
    best_slot = slot
  if best_slot < 0: return
  if gm.open_pack(best_slot):
   take_from_pack()
   opened = true

func take_from_pack() -> void:
 while not gm.opened_pack.is_empty():
  var choices: Array = gm.opened_pack.choices
  var pick: int = -1
  var pick_value: float = 0.0
  for i: int in range(choices.size()):
   var value: float = choice_value(choices[i])
   if value > pick_value and gm.pack_block_reason(choices[i]).is_empty():
    pick_value = value
    pick = i
  if pick < 0:
   gm.skip_pack()
   return
  gm.take_pack_card(pick)

func choice_value(choice: Dictionary) -> float:
 match String(choice.type):
  "joker":
   var item: JokerData = gm.joker_by_id(String(choice.id))
   return worth(item,String(choice.get("edition","")))
  "recipe":
   # Level the recipe this run actually plays most.
   return 1.0+float(recipe_counts.get(String(choice.id),0))
  "candy":
   var candy: CandyData = gm.config.candies[int(choice.id)]
   return 1.0+candy.spawn_weight*float(candy.base_chips)
  "rush":
   match String(choice.id):
    "cookbook_blast": return 10.0
    "glitter": return 8.0 if gm.has_plain_joker() else 0.0
    "big_spoon": return 6.0 if gm.gummies >= 14 else 0.0
    "golden_batch": return 4.0
    "meltdown": return 0.0
 return 0.0

func build_text() -> String:
 var parts: PackedStringArray = []
 for item: JokerData in gm.jokers.equipped:
  var edition: String = gm.jokers.edition(item.id)
  parts.append(item.id+("(%s)" % edition if edition != "" else ""))
 return ",".join(parts)

func levels_text() -> String:
 var parts: PackedStringArray = []
 for id: String in RecipeCatalog.ORDER: parts.append("%s%d" % [id.left(2),gm.recipe_level(id)])
 return "".join(parts)
