class_name CandyState
extends RefCounted
var color: int = 0
var coating: int = 0 # 0 normal, 1 caramel, 2 gold, 3 wild
var blocker: int = 0
var age: int = 0
func _init(value: int = 0) -> void:
 color = value
func value(config: RunConfig, bonus: int = 0) -> int:
 if coating == 2: return config.gold_chips+bonus
 if coating == 1: return config.caramel_chips+bonus
 return config.candies[color].base_chips+bonus
func chips(config: RunConfig, bonus: int = 0) -> int:
 if blocker > 0: return 0
 return value(config,bonus)
