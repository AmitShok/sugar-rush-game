extends Control
# Interactive title screen (v0.33). No panel: the logo, buttons and cards sit on the swirl.
# - SUGAR RUSH logo: letters wave and shimmer; tap a letter to make it jump and play a note.
# - Candies drift down behind everything; tap one to pop it (quick pops climb in pitch).
# - Joker cards fan out on both sides; tap one to flip it to a new Joker (rolled with rarity odds)
#   and see its name and rarity.
# - Menu buttons cascade in when the title opens and swell on hover.
# Everything respects the Motion option and only runs while the title is showing.
const LOGO: String = "SUGAR RUSH"
const LETTER_COLORS: Array[Color] = [Color("ff7eb6"),Color("ffd166"),Color("7ee8a2"),Color("6ec8ff"),Color("c792ff"),Color("ff9f68")]
const NOTES: Array[float] = [1.0,1.125,1.25,1.5,1.667,2.0] # Major pentatonic steps for letter taps.
const CARD_SPOTS: Array[Dictionary] = [
 {"pos":Vector2(70,268),"rot":-12.0},{"pos":Vector2(170,318),"rot":-3.0},{"pos":Vector2(110,470),"rot":-8.0},
 {"pos":Vector2(842,318),"rot":3.0},{"pos":Vector2(942,268),"rot":12.0},{"pos":Vector2(902,470),"rot":8.0},
]
const MAX_CANDIES: int = 16
const LOGO_Y: float = 80.0
const LOGO_SCALE: float = 1.7
var time: float = 0.0
var letters: Array[Label] = []
var letter_jump: Array[float] = []
var candy_layer: Control
var candies: Array[Dictionary] = [] # {"node","speed","spin"}
var spawn_timer: float = 0.0
var pop_streak: int = 0
var last_pop: float = -10.0
var popped: int = 0
var cards: Array[Dictionary] = [] # {"holder","face","item","base","rot","label"}
var tagline: Label
var pop_label: Label
var random: RandomNumberGenerator = RandomNumberGenerator.new() # Cosmetic only; never touches run seeds.
var was_visible: bool = false
var mouse: Vector2 = Vector2(576,360)

func _ready() -> void:
 set_anchors_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 random.randomize()
 candy_layer = Control.new()
 candy_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
 candy_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(candy_layer)
 build_cards()
 build_logo()
 pop_label = UIStyle.label("",24,UIStyle.MUTED)
 pop_label.position = Vector2(24,680)
 pop_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(pop_label)
 # Pre-fill the sky so the screen is alive from the first frame.
 for i: int in range(8): spawn_candy(random.randf_range(-40.0,680.0))
 call_deferred("strip_menu_panel")

# The title buttons float on the swirl without a box; empty space passes clicks to the candies.
func strip_menu_panel() -> void:
 var menu: Control = get_parent().get_node_or_null("Menu") as Control
 if menu == null: return
 menu.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
 menu.position = Vector2(406,292)
 menu.custom_minimum_size = Vector2(340,0)
 var layout: Control = menu.get_node("Layout") as Control
 layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
 for key: String in ["Eyebrow","Title","Subtitle","Description"]:
  var node: Control = layout.get_node_or_null(key) as Control
  if node: node.visible = false
 for child: Node in layout.get_children():
  if child is Button:
   var button: Button = child as Button
   button.mouse_entered.connect(hover_button.bind(button,true))
   button.mouse_exited.connect(hover_button.bind(button,false))
   button.focus_entered.connect(hover_button.bind(button,true))
   button.focus_exited.connect(hover_button.bind(button,false))
 var footer: Label = layout.get_node_or_null("Footer") as Label
 if footer:
  footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  footer.add_theme_color_override("font_color",UIStyle.MUTED)
 # Shrink to the visible buttons once the hidden title labels stop counting.
 menu.call_deferred("reset_size")

func hover_button(button: Button, on: bool) -> void:
 if not GameManager.motion or not is_visible_in_tree(): return
 button.pivot_offset = button.size*0.5
 create_tween().tween_property(button,"scale",Vector2.ONE*(1.06 if on else 1.0),0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func build_logo() -> void:
 var eyebrow: Label = UIStyle.label("FLOOR 38 PRESENTS",24,UIStyle.MUTED)
 eyebrow.position = Vector2(0,12)
 eyebrow.size = Vector2(1152,30)
 eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 eyebrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(eyebrow)
 var font_size: int = 64 # Bitmap m6x11 tops out at 64 px; LOGO_SCALE enlarges it crisply.
 var advance: float = 62.0
 var start: float = 576.0-advance*LOGO.length()*0.5
 for i: int in range(LOGO.length()):
  var letter: LogoLetter = LogoLetter.new()
  letter.text = LOGO[i]
  letter.add_theme_font_override("font",UIStyle.FONT)
  letter.add_theme_font_size_override("font_size",font_size)
  letter.add_theme_color_override("font_color",LETTER_COLORS[i%LETTER_COLORS.size()])
  letter.add_theme_color_override("font_shadow_color",Color("1c1022"))
  letter.add_theme_constant_override("shadow_offset_x",0)
  letter.add_theme_constant_override("shadow_offset_y",8)
  letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  letter.size = Vector2(advance,90)
  letter.position = Vector2(start+advance*i,LOGO_Y)
  letter.pivot_offset = Vector2(advance*0.5,45)
  letter.mouse_filter = Control.MOUSE_FILTER_STOP if LOGO[i] != " " else Control.MOUSE_FILTER_IGNORE
  letter.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  letter.gui_input.connect(on_letter_input.bind(i))
  add_child(letter)
  letters.append(letter)
  letter_jump.append(0.0)
 tagline = UIStyle.label("Match candy. Bend the rules.",24,UIStyle.CREAM)
 tagline.position = Vector2(0,206)
 tagline.size = Vector2(1152,30)
 tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(tagline)

func on_letter_input(event: InputEvent, i: int) -> void:
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
  letter_jump[i] = 1.0
  SoundBoard.play("tick",NOTES[i%NOTES.size()]*(1.0 if i < 5 else 1.5),-2.0)
  letters[i].accept_event()

func build_cards() -> void:
 var pool: Array[JokerData] = []
 pool.assign(GameManager.config.jokers)
 for spot: Dictionary in CARD_SPOTS:
  var holder: Control = Control.new()
  holder.size = Vector2(140,188)
  holder.position = spot.pos
  holder.rotation_degrees = spot.rot
  holder.pivot_offset = holder.size*0.5
  holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(holder)
  var face: TextureRect = TextureRect.new()
  face.size = holder.size
  face.pivot_offset = holder.size*0.5
  face.mouse_filter = Control.MOUSE_FILTER_STOP
  face.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  holder.add_child(face)
  var label: Label = UIStyle.label("",24,UIStyle.CREAM)
  label.size = Vector2(240,60)
  label.position = Vector2(-50,196)
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  label.add_theme_color_override("font_shadow_color",Color("1c1022"))
  label.add_theme_constant_override("shadow_offset_y",3)
  label.modulate.a = 0.0
  label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  holder.add_child(label)
  var card: Dictionary = {"holder":holder,"face":face,"item":null,"base":spot.pos,"rot":spot.rot,"label":label,"flipping":false}
  cards.append(card)
  face.gui_input.connect(on_card_input.bind(card))
  set_card(card,roll_card())
  CardTilt.attach(face)

# Menu cards use the same rarity odds as the shop, so Legendaries are a rare sight here too.
func roll_card() -> JokerData:
 var pool: Array = []
 var shown: Array = []
 for card: Dictionary in cards: shown.append(card.item)
 for item: JokerData in GameManager.config.jokers:
  if item not in shown: pool.append(item)
 var index: int = JokerRarity.pick_index(pool,random)
 return pool[index] as JokerData

func set_card(card: Dictionary, item: JokerData) -> void:
 card.item = item
 (card.face as TextureRect).texture = item.icon
 var tilt: CardTilt = (card.face as Control).get_node_or_null("CardTilt") as CardTilt
 # A rare cosmetic edition shimmer makes the fan sparkle now and then.
 if tilt: tilt.edition = ["","","","","foil","holo","poly"][random.randi_range(0,6)] if item.rarity != "Common" else ""

func on_card_input(event: InputEvent, card: Dictionary) -> void:
 if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT): return
 (card.face as Control).accept_event()
 if card.flipping: return
 SoundBoard.play("card_take",random.randf_range(0.95,1.1))
 var next: JokerData = roll_card()
 if not GameManager.motion:
  set_card(card,next)
  show_card_label(card)
  return
 card.flipping = true
 var face: Control = card.face
 var tween: Tween = create_tween()
 tween.tween_property(face,"scale:x",0.0,0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
 tween.tween_callback(func() -> void: set_card(card,next))
 tween.tween_property(face,"scale:x",1.0,0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
 tween.tween_callback(func() -> void: card.flipping = false; show_card_label(card))

func show_card_label(card: Dictionary) -> void:
 var item: JokerData = card.item
 var label: Label = card.label
 label.text = "%s\n%s" % [item.display_name,item.rarity.to_upper()]
 label.add_theme_color_override("font_color",JokerRarity.color(item.rarity))
 label.rotation_degrees = -float(card.rot)
 if item.rarity == "Legendary": SoundBoard.play("special_make")
 var tween: Tween = create_tween()
 tween.tween_property(label,"modulate:a",1.0,0.15)
 tween.tween_interval(1.6)
 tween.tween_property(label,"modulate:a",0.0,0.5)

func spawn_candy(y: float = -60.0) -> void:
 var candy: TextureRect = RoundCandy.new()
 var index: int = random.randi_range(0,GameManager.config.candies.size()-1)
 candy.texture = GameManager.config.candies[index].texture
 var scale_factor: float = random.randf_range(0.8,1.3)
 candy.size = Vector2(48,48)*scale_factor
 candy.pivot_offset = candy.size*0.5
 candy.position = Vector2(random.randf_range(10.0,1100.0),y)
 candy.rotation = random.randf_range(-PI,PI)
 candy.modulate.a = 0.85
 candy.mouse_filter = Control.MOUSE_FILTER_STOP
 candy.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 candy_layer.add_child(candy)
 var entry: Dictionary = {"node":candy,"speed":random.randf_range(45.0,95.0)*scale_factor,"spin":random.randf_range(-1.2,1.2),"tint":GameManager.config.candies[index].tint,"sway":random.randf_range(0.0,TAU)}
 candies.append(entry)
 candy.gui_input.connect(on_candy_input.bind(entry))

func on_candy_input(event: InputEvent, entry: Dictionary) -> void:
 if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT): return
 var candy: TextureRect = entry.node
 candy.accept_event()
 pop_streak = pop_streak+1 if time-last_pop < 1.5 else 1
 last_pop = time
 popped += 1
 pop_label.text = "%s popped" % popped if pop_streak < 3 else "%s popped  x%s streak!" % [popped,pop_streak]
 SoundBoard.play("match_big",minf(0.9+0.08*pop_streak,2.0),-3.0)
 burst(candy.position+candy.size*0.5,entry.tint)
 candies.erase(entry)
 candy.mouse_filter = Control.MOUSE_FILTER_IGNORE
 if GameManager.motion:
  var tween: Tween = create_tween().set_parallel()
  tween.tween_property(candy,"scale",Vector2.ONE*1.6,0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  tween.tween_property(candy,"modulate",Color(2.0,2.0,2.0,0.0),0.16)
  tween.chain().tween_callback(candy.queue_free)
 else: candy.queue_free()

func burst(center: Vector2, tint: Color) -> void:
 if not GameManager.motion: return
 for i: int in range(10):
  var bit: ColorRect = ColorRect.new()
  bit.size = Vector2(6,6)
  bit.color = tint.lightened(0.25) if i%2 == 0 else UIStyle.CREAM
  bit.position = center-bit.size*0.5
  bit.mouse_filter = Control.MOUSE_FILTER_IGNORE
  candy_layer.add_child(bit)
  var angle: float = TAU*i/10.0+random.randf_range(-0.2,0.2)
  var distance: float = random.randf_range(36.0,70.0)
  var tween: Tween = create_tween().set_parallel()
  tween.tween_property(bit,"position",bit.position+Vector2.from_angle(angle)*distance,0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  tween.tween_property(bit,"modulate:a",0.0,0.35)
  tween.chain().tween_callback(bit.queue_free)

# Buttons drop in one after another whenever the title appears.
func play_intro() -> void:
 pop_streak = 0
 var menu: Control = get_parent().get_node_or_null("Menu") as Control
 if menu == null or not GameManager.motion: return
 var delay: float = 0.0
 for child: Node in menu.get_node("Layout").get_children():
  var item: Control = child as Control
  if item == null or not item.visible: continue
  item.pivot_offset = item.size*0.5
  item.scale = Vector2.ONE*0.6
  item.modulate.a = 0.0
  var tween: Tween = create_tween().set_parallel()
  tween.tween_property(item,"scale",Vector2.ONE,0.32).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  tween.tween_property(item,"modulate:a",1.0,0.2).set_delay(delay)
  delay += 0.05
 for i: int in range(letter_jump.size()): letter_jump[i] = 0.6+0.04*i

func _input(event: InputEvent) -> void:
 if event is InputEventMouseMotion: mouse = (event as InputEventMouseMotion).position

func _process(delta: float) -> void:
 visible = GameManager.state == "menu"
 if visible and not was_visible: play_intro()
 was_visible = visible
 if not visible: return
 time += delta
 var motion: bool = GameManager.motion
 # Gentle parallax: the scene leans away from the pointer.
 var lean: Vector2 = ((mouse-Vector2(576,360))/Vector2(576,360)).clamp(-Vector2.ONE,Vector2.ONE) if motion else Vector2.ZERO
 for i: int in range(letters.size()):
  var letter: Label = letters[i]
  letter_jump[i] = maxf(0.0,letter_jump[i]-delta*2.4)
  var jump: float = sin(letter_jump[i]*PI)*36.0
  var wave: float = sin(time*2.6-i*0.55)*7.0 if motion else 0.0
  letter.position.y = LOGO_Y+wave-jump-lean.y*4.0
  letter.rotation_degrees = sin(time*1.9-i*0.7)*4.0 if motion else 0.0
  var base: Color = LETTER_COLORS[i%LETTER_COLORS.size()]
  var shimmer: float = maxf(0.0,sin(time*1.6-i*0.45))
  letter.add_theme_color_override("font_color",base.lerp(Color.WHITE,pow(shimmer,8.0)*0.6) if motion else base)
  letter.scale = Vector2.ONE*LOGO_SCALE*(1.0+sin(letter_jump[i]*PI)*0.18)
 if tagline: tagline.modulate.a = 0.75+0.25*sin(time*2.0) if motion else 1.0
 for i: int in range(cards.size()):
  var card: Dictionary = cards[i]
  var holder: Control = card.holder
  var bob: float = sin(time*1.1+i*1.3)*8.0 if motion else 0.0
  holder.position = Vector2(card.base)+Vector2(0,bob)-lean*Vector2(10,6)
  holder.rotation_degrees = float(card.rot)+(sin(time*0.8+i)*2.0 if motion else 0.0)
 if not motion: return
 spawn_timer -= delta
 if spawn_timer <= 0.0 and candies.size() < MAX_CANDIES:
  spawn_timer = random.randf_range(0.35,0.8)
  spawn_candy()
 for entry: Dictionary in candies.duplicate():
  var candy: TextureRect = entry.node
  candy.position.y += float(entry.speed)*delta
  candy.position.x += sin(time*1.3+float(entry.sway))*12.0*delta
  candy.rotation += float(entry.spin)*delta
  if candy.position.y > 740.0:
   candies.erase(entry)
   candy.queue_free()

# Logo letters only react inside the visible glyph, not their whole (scaled-up) label box.
# m6x11 capitals sit between 1/4 and 4/4 of the ascent and are the advance minus 1 px spacing wide.
class LogoLetter extends Label:
 const PAD: float = 4.0
 func glyph_rect() -> Rect2:
  var font: Font = get_theme_font("font")
  var font_size: int = get_theme_font_size("font_size")
  var ascent: float = font.get_ascent(font_size)
  var advance: float = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
  var spacing: float = font_size/16.0
  var width: float = advance-spacing
  return Rect2((size.x-advance)*0.5,ascent*0.25,width,ascent*0.75).grow(PAD)
 func _has_point(point: Vector2) -> bool:
  return glyph_rect().has_point(point)

# Candies are round: only the disc counts, not the transparent corners of their 48 px tile.
class RoundCandy extends TextureRect:
 func _has_point(point: Vector2) -> bool:
  return point.distance_to(size*0.5) <= size.x*0.42
