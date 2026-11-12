class_name SugarTile
extends Control
@export var idle_bob: float = 1.4
var cell_index: int = 0
var data: CandyState
var selected: bool = false
var hinted: bool = false
var hovered: bool = false
var isotope: bool = false
var locked: bool = false
var roulette: bool = false
var jelly: bool = false
var sour: bool = false
# Idle sparkle (v0.24): a short glint now and then on resting candies. Cosmetic only; uses the global RNG.
var glint_wait: float = randf_range(2.0,14.0)
var glint_left: float = 0.0
const GLINT_TIME: float = 0.45
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
func configure(i: int, value: CandyState, run_config: RunConfig, is_isotope: bool, is_locked: bool, bonus: int = 0, is_roulette: bool = false) -> void:
 cell_index = i
 data = value
 isotope = is_isotope
 locked = is_locked
 roulette = is_roulette
 sprite.texture = UIStyle.texture("candy_bomb") if data.special == CandyState.BOMB else run_config.candies[data.color].texture
 sprite.modulate = Color("ffe59a") if data.coating == 2 else Color.WHITE
 tooltip_text = "%s | %s Candys%s%s" % [run_config.candies[data.color].display_name,data.value(run_config,bonus)," | LOCKED" if locked else ""," | Isotope x4" if isotope else ""]
 if roulette: tooltip_text += " | Roulette: x2 Mult on matches"
 if data.special == CandyState.BOMB: tooltip_text = "Color Bomb | Swap with a candy to clear its type. Swap with a special for a combo."
 elif data.special != CandyState.NONE: tooltip_text += " | %s: match it or blast it to fire" % CandyState.special_name(data.special)
 if data.chocolate: tooltip_text = "Chocolate | Match beside it or blast it to break it. It spreads after moves that break none."
 elif data.frosting > 0: tooltip_text = "Frosting (%s %s left) | Each nearby match or blast removes one layer." % [data.frosting,"layer" if data.frosting == 1 else "layers"]
 sprite.visible = not data.obstacle()
 queue_redraw()
func _process(delta: float) -> void:
 elapsed += delta
 if GameManager.motion and data != null and not data.obstacle():
  if glint_left > 0.0:
   glint_left -= delta
   queue_redraw()
  else:
   glint_wait -= delta
   if glint_wait <= 0.0:
    glint_left = GLINT_TIME
    glint_wait = randf_range(6.0,16.0)
 if is_instance_valid(sprite): sprite.position.y = 4.0 + (sin(elapsed*2.0+cell_index)*idle_bob if GameManager.motion and (selected or hinted) else 0.0)
func mark(name: String) -> void:
 draw_texture(UIStyle.texture("ui_"+name),Vector2.ZERO)
func _draw() -> void:
 if has_node("Floor"): $Floor.texture = UIStyle.texture("ui_tile_a" if (cell_index/8+cell_index%8)%2==0 else "ui_tile_b")
 if hovered and not selected: mark("hover")
 if isotope: mark("isotope")
 if jelly: mark("mark_jelly")
 if data != null:
  if data.coating == 2: mark("gold")
  if data.coating == 1: mark("caramel")
  if data.coating == 3: mark("wild")
  if data.special == CandyState.STRIPE_H: mark("striped_h")
  elif data.special == CandyState.STRIPE_V: mark("striped_v")
  elif data.special == CandyState.WRAPPED: mark("wrapped")
  if data.chocolate: mark("chocolate")
  elif data.frosting > 0: mark("frost_%s" % mini(data.frosting,2))
  if sour and not data.obstacle(): mark("mark_sour")
  if data.blocker > 0: mark("blocker")
  elif locked: mark("lock")
 if selected or hinted: mark("selected" if selected else "hint")
 if roulette: mark("roulette")
 if glint_left > 0.0 and GameManager.motion:
  var phase: float = 1.0-absf(glint_left/GLINT_TIME*2.0-1.0)
  draw_texture(UIStyle.texture("ui_glint"),Vector2(10,8),Color(1,1,1,phase))
