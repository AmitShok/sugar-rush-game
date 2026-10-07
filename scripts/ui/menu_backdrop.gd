extends Node2D
@export var drift_speed: float = 0.8
@export var drift_height: float = 7.0
var time: float = 0.0
var origins: Dictionary = {}
func _ready() -> void:
 for item: Node2D in get_children(): origins[item] = item.position
func _process(delta: float) -> void:
 visible = GameManager.state == "menu"
 if not visible: return
 time += delta
 var phase: float = 0.0
 for item: Node2D in get_children():
  item.position = origins[item]
  if GameManager.motion: item.position.y += roundf(sin(time*drift_speed+phase)*drift_height)
  phase += 1.7
