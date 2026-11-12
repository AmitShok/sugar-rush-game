class_name CardTilt
extends Node
# Attach to a card Control (TextureButton/TextureRect). It tilts toward the pointer, lifts on hover,
# and sways gently at rest (v0.25). Use CardTilt.attach(card). Respects the Reduced motion option.
const SHADER: Shader = preload("res://shaders/card_tilt.gdshader")
const HOVER_SCALE: float = 1.07
var card: Control
var hovering: bool = false
var current: Vector2 = Vector2.ZERO
var lift: float = 0.0
var phase: float = 0.0
# Joker edition drawn by the card shader (v0.30): "", "foil", "holo" or "poly".
var edition: String = ""
var clock: float = 0.0
const EDITION_IDS: Dictionary = {"foil":1,"holo":2,"poly":3}
static func attach(target: Control) -> CardTilt:
 var existing: Node = target.get_node_or_null("CardTilt")
 if existing: return existing as CardTilt
 var tilt: CardTilt = CardTilt.new()
 tilt.name = "CardTilt"
 target.add_child(tilt)
 return tilt
func _ready() -> void:
 card = get_parent() as Control
 var material: ShaderMaterial = ShaderMaterial.new()
 material.shader = SHADER
 card.material = material
 card.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 card.mouse_entered.connect(func() -> void: hovering = true)
 card.mouse_exited.connect(func() -> void: hovering = false)
 phase = float(card.get_instance_id() % 997)*0.37
func _process(delta: float) -> void:
 if not is_instance_valid(card) or not card.is_visible_in_tree(): return
 var target: Vector2 = Vector2.ZERO
 if GameManager.motion: clock += delta
 if GameManager.motion:
  phase += delta
  if hovering and card.size.x > 0.0:
   var local: Vector2 = card.get_local_mouse_position()/card.size-Vector2(0.5,0.5)
   target = Vector2(clampf(local.x*2.0,-1.0,1.0),clampf(local.y*2.0,-1.0,1.0))
  else:
   target = Vector2(sin(phase*1.3),cos(phase*1.1))*0.12
 current = current.lerp(target,clampf(delta*10.0,0.0,1.0))
 lift = lerpf(lift,1.0 if hovering and GameManager.motion else 0.0,clampf(delta*12.0,0.0,1.0))
 card.pivot_offset = card.size*0.5
 card.scale = Vector2.ONE*(1.0+(HOVER_SCALE-1.0)*lift)
 var material: ShaderMaterial = card.material as ShaderMaterial
 if material:
  material.set_shader_parameter("tilt",current)
  material.set_shader_parameter("sheen",lift)
  material.set_shader_parameter("edition",int(EDITION_IDS.get(edition,0)))
  material.set_shader_parameter("clock",clock)
