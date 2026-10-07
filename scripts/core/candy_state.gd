class_name CandyState
extends RefCounted
var color: int = 0
var coating: int = 0 # 0 normal, 1 caramel, 2 gold, 3 wild
var blocker: int = 0
var age: int = 0
func _init(value: int = 0) -> void:
 color = value
func chips(config: RunConfig) -> int:
 if blocker > 0: return 0
 if coating == 2: return config.gold_chips
 if coating == 1: return config.caramel_chips
 return config.candies[color].base_chips
