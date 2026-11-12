class_name CandyState
extends RefCounted
# Special candies (made by the Striper / Wrapper / Bomb Maker Jokers).
const NONE: int = 0
const STRIPE_H: int = 1 # clears its row
const STRIPE_V: int = 2 # clears its column
const WRAPPED: int = 3 # 3x3 blast
const BOMB: int = 4 # colorless; swap to clear a color
var color: int = 0
var coating: int = 0 # 0 normal, 1 caramel, 2 gold, 3 wild
var blocker: int = 0
var age: int = 0
var special: int = NONE
# Boss obstacles (v0.22): chocolate and frosting fill a cell instead of a candy.
var chocolate: bool = false
var frosting: int = 0 # layers left
func obstacle() -> bool:
 return chocolate or frosting > 0
func _init(value: int = 0) -> void:
 color = value
func value(config: RunConfig, bonus: int = 0) -> int:
 if coating == 2: return config.gold_chips+bonus
 if coating == 1: return config.caramel_chips+bonus
 return config.candies[color].base_chips+bonus
func chips(config: RunConfig, bonus: int = 0) -> int:
 if blocker > 0 or obstacle(): return 0
 return value(config,bonus)
static func special_name(kind: int) -> String:
 return ["","Striped (row)","Striped (column)","Wrapped","Color Bomb"][clampi(kind,0,4)]
