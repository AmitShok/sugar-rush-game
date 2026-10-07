class_name SugarTile
extends Control
signal chosen(index: int)
@export var idle_bob: float = 1.4
var cell_index: int = 0
var data: CandyState
var selected: bool = false
var hinted: bool = false
var hovered: bool = false
var isotope: bool = false
var locked: bool = false
var elapsed: float = 0.0
@onready var sprite: TextureRect = $Icon
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 sprite.show_behind_parent = true
 var floor_tile: TextureRect = TextureRect.new()
 floor_tile.name = "Floor"
 floor_tile.texture = UIStyle.texture("ui_tile_a")
 floor_tile.size = Vector2(56,56)
 floor_tile.show_behind_parent = true
 floor_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(floor_tile)
 move_child(floor_tile,0)
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
func configure(i: int, value: CandyState, run_config: RunConfig, is_isotope: bool, is_locked: bool) -> void:
 cell_index = i
 data = value
 isotope = is_isotope
 locked = is_locked
 sprite.texture = run_config.candies[data.color].texture
 sprite.modulate = Color("ffe59a") if data.coating == 2 else Color.WHITE
 tooltip_text = "%s | %s Candys%s%s" % [run_config.candies[data.color].display_name,data.chips(run_config)," | LOCKED" if locked else ""," | Isotope x4" if isotope else ""]
 queue_redraw()
func _process(delta: float) -> void:
 elapsed += delta
 if is_instance_valid(sprite): sprite.position.y = 4.0 + (sin(elapsed*2.0+cell_index)*idle_bob if GameManager.motion and (selected or hinted) else 0.0)
func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
  chosen.emit(cell_index)
  accept_event()
func mark(name: String) -> void:
 draw_texture(UIStyle.texture("ui_"+name),Vector2.ZERO)
func _draw() -> void:
 if has_node("Floor"): $Floor.texture = UIStyle.texture("ui_tile_a" if (cell_index/8+cell_index%8)%2==0 else "ui_tile_b")
 if hovered and not selected: mark("hover")
 if isotope: mark("isotope")
 if data != null:
  if data.coating == 2: mark("gold")
  if data.coating == 1: mark("caramel")
  if data.coating == 3: mark("wild")
  if data.blocker > 0: mark("blocker")
  elif locked: mark("lock")
 if selected or hinted: mark("selected" if selected else "hint")
