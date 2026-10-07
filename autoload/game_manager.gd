extends Node
signal changed
signal round_started
signal shop_opened
signal run_ended(won: bool)
signal toast(message: String)
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
var offers: Array[JokerData] = []
var reroll_cost: int = 3
func _ready() -> void:
 jokers = preload("res://scenes/JokerManager.tscn").instantiate() as JokerManager
 jokers.name = "JokerManager"
 add_child(jokers)
 jokers.capacity = config.joker_slots
 var prefs: ConfigFile = ConfigFile.new()
 if prefs.load("user://preferences.cfg") == OK:
  motion = prefs.get_value("settings","motion",true)
  sound = prefs.get_value("settings","sound",true)
func save_preferences() -> void:
 var prefs: ConfigFile = ConfigFile.new()
 prefs.set_value("settings","motion",motion)
 prefs.set_value("settings","sound",sound)
 prefs.save("user://preferences.cfg")
func current_round() -> RoundData:
 return config.rounds[round_index]
func start_run(seed_value: int = 0) -> void:
 run_seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
 rng.seed = run_seed
 round_index = 0
 gummies = config.starting_gummies
 jokers.equipped.clear()
 start_round()
func start_round() -> void:
 score = 0
 streak = 0
 moves = current_round().moves
 poison = rng.randi_range(0,config.candies.size()-1) if jokers.has("roulette") else -1
 poison_cleared = false
 last_chips = 0
 last_mult = 1
 state = "playing"
 round_started.emit()
 changed.emit()
func begin_move(valid: bool) -> void:
 moves -= 1
 streak = streak+1 if valid else 0
 changed.emit()
func award(result: Dictionary, color: int) -> void:
 score += int(result.total)
 last_chips = result.chips
 last_mult = result.mult
 if color == poison: poison_cleared = true
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
  last_award = reward+move_bonus
  gummies += last_award
  last_summary = "Round $%s + saved moves $%s = $%s" % [reward,move_bonus,last_award]
  if round_index == config.rounds.size()-1:
   state = "over"
   run_ended.emit(true)
  else:
   state = "shop"
   reroll_cost = config.base_reroll_cost
   roll_offers()
   shop_opened.emit()
 changed.emit()
func round_reward() -> int:
 match round_index % 3:
  1: return config.big_reward
  2: return config.boss_reward
 return config.clear_reward
func roll_offers() -> void:
 offers.clear()
 var pool: Array[JokerData] = []
 for item: JokerData in config.jokers:
  if not jokers.has(item.id): pool.append(item)
 while offers.size() < 4 and not pool.is_empty():
  var i: int = rng.randi_range(0,pool.size()-1)
  offers.append(pool[i])
  pool.remove_at(i)
func buy(item: JokerData) -> bool:
 if state != "shop" or item not in offers or gummies < item.price or not jokers.can_add(item): return false
 gummies -= item.price
 jokers.add(item)
 offers.erase(item)
 changed.emit()
 return true
func sell(item: JokerData) -> void:
 if state != "shop" or item not in jokers.equipped: return
 gummies += item.price/2
 jokers.remove(item)
 changed.emit()
func reroll() -> void:
 if state != "shop" or gummies < reroll_cost: return
 gummies -= reroll_cost
 reroll_cost += config.reroll_increment
 roll_offers()
 changed.emit()
func next_round() -> void:
 if state != "shop": return
 round_index += 1
 start_round()
