class_name UIStyle
extends RefCounted
const INK: Color = Color("1c1022")
const CREAM: Color = Color("fff8e7")
const MUTED: Color = Color("c9b6d4")
const PINK: Color = Color("ef6355")
const MINT: Color = Color("f5b957")
const BODY_FONT: Font = preload("res://assets/exported/readable_font.fnt")
# m6x11 (Daniel Linssen) for headings, numbers and big buttons (v0.25, Balatro look); 16 px base.
const FONT: Font = preload("res://assets/exported/ui_font.fnt")
# m6x11 is crisp at multiples of 16 px.
static func pixel_size(size: int) -> int:
 if size >= 56: return 64
 if size >= 40: return 48
 return 32
static var textures: Dictionary = {}
static func texture(name: String) -> Texture2D:
 if not textures.has(name): textures[name] = load("res://assets/exported/"+name+".png")
 return textures[name] as Texture2D
static func skin(name: String) -> StyleBoxTexture:
 var style: StyleBoxTexture = StyleBoxTexture.new()
 style.texture = texture(name)
 # v0.25 rounded skins are 32 x 32 with 7 px corners and a 3 px raised lip.
 style.texture_margin_left = 10
 style.texture_margin_right = 10
 style.texture_margin_top = 10
 style.texture_margin_bottom = 10
 style.content_margin_left = 14
 style.content_margin_right = 14
 style.content_margin_top = 10
 style.content_margin_bottom = 12
 return style
static func box(color: Color, _border: Color = Color("677b80"), _width: int = 2) -> StyleBoxTexture:
 var name: String = "ui_panel"
 if color.a == 0: name = "ui_focus"
 elif color.r > 0.8 and color.g > 0.5: name = "ui_progress_gold"
 elif color.b > 0.6 and color.b > color.r*1.5 and color.b > color.g: name = "ui_blue"
 elif color.r > color.g*1.4: name = "ui_button"
 elif color.g > color.r*1.7 and color.g > 0.4: name = "ui_green"
 elif color.r < 0.15: name = "ui_inset"
 return skin(name)
static func apply(root: Control) -> void:
 var theme: Theme = Theme.new()
 theme.default_font = BODY_FONT
 theme.default_font_size = 32
 theme.set_color("font_color","Label",CREAM)
 theme.set_color("font_shadow_color","Label",Color("1c1022"))
 theme.set_constant("shadow_offset_x","Label",0)
 theme.set_constant("shadow_offset_y","Label",0)
 theme.set_color("font_color","Button",CREAM)
 theme.set_color("font_hover_color","Button",Color.WHITE)
 theme.set_color("font_shadow_color","Button",Color("3c2420"))
 theme.set_constant("shadow_offset_y","Button",0)
 theme.set_stylebox("panel","PanelContainer",box(Color("344951"),Color("65797b"),3))
 theme.set_stylebox("normal","Button",box(Color("ba493e"),Color("f07859"),2))
 theme.set_stylebox("hover","Button",skin("ui_button_hover"))
 theme.set_stylebox("pressed","Button",skin("ui_button_pressed"))
 var focus: StyleBoxTexture = box(Color(0,0,0,0),MINT,2)
 theme.set_stylebox("focus","Button",focus)
 theme.set_stylebox("disabled","Button",skin("ui_disabled"))
 theme.set_color("font_disabled_color","Button",Color("a898b2"))
 for state: String in ["normal","hover","pressed","focus","disabled"]:
  var button_style: StyleBoxTexture = theme.get_stylebox(state,"Button") as StyleBoxTexture
  button_style.content_margin_top = 5
  button_style.content_margin_bottom = 5
 theme.set_constant("separation","VBoxContainer",8)
 theme.set_constant("separation","HBoxContainer",12)
 theme.set_stylebox("background","ProgressBar",box(Color("172b30"),Color("536564")))
 theme.set_stylebox("fill","ProgressBar",box(Color("f5b957"),Color("f5b957"),0))
 theme.set_stylebox("normal","LineEdit",box(Color("20353b"),Color("84978e")))
 theme.set_font("normal_font","RichTextLabel",BODY_FONT)
 theme.set_font("bold_font","RichTextLabel",BODY_FONT)
 for type: String in ["CheckButton","CheckBox"]:
  for state: String in ["checked","checked_disabled"]: theme.set_icon(state,type,texture("ui_toggle_on"))
  for state: String in ["unchecked","unchecked_disabled"]: theme.set_icon(state,type,texture("ui_toggle_off"))
 for state: String in ["scroll","scroll_focus"]: theme.set_stylebox(state,"VScrollBar",skin("ui_inset"))
 for state: String in ["grabber","grabber_highlight","grabber_pressed"]: theme.set_stylebox(state,"VScrollBar",skin("ui_progress_gold"))
 for icon_name: String in ["increment","increment_highlight","increment_pressed","decrement","decrement_highlight","decrement_pressed"]:
  theme.set_icon(icon_name,"VScrollBar",texture("ui_arrow"))
 theme.set_stylebox("panel","TooltipPanel",skin("ui_inset"))
 theme.set_stylebox("slider","HSlider",skin("ui_inset"))
 theme.set_stylebox("grabber_area","HSlider",skin("ui_progress_gold"))
 theme.set_stylebox("grabber_area_highlight","HSlider",skin("ui_progress_gold"))
 for state: String in ["grabber","grabber_highlight","grabber_disabled"]: theme.set_icon(state,"HSlider",texture("ui_volume_knob"))
 root.theme = theme
 preserve_headings(root)
static func preserve_headings(node: Node) -> void:
 if (node is Label or node is Button) and node.get_theme_font_size("font_size") >= 32:
  node.add_theme_font_override("font",FONT)
  node.add_theme_font_size_override("font_size",pixel_size(node.get_theme_font_size("font_size")))
 for child: Node in node.get_children(): preserve_headings(child)
static func label(text: String,size: int = 32,color: Color = CREAM) -> Label:
 var node: Label = Label.new()
 node.text = text
 node.add_theme_font_override("font",FONT if size >= 32 else BODY_FONT)
 if size >= 32: size = pixel_size(size)
 node.add_theme_font_size_override("font_size",size)
 node.add_theme_color_override("font_color",color)
 return node

static func money(value: int) -> String:
 var digits: String = str(absi(value))
 var grouped: String = ""
 for i: int in range(digits.length()):
  if i > 0 and (digits.length()-i)%3 == 0: grouped += ","
  grouped += digits[i]
 return ("-$" if value < 0 else "$")+grouped
# Button roles (v0.24 candy-shop art): go, info, buy, skip, danger, neutral. Default buttons are berry pink.
const ROLES: Array[String] = ["go","info","buy","skip","danger","neutral"]
static func role(button: Button, kind: String) -> void:
 if kind not in ROLES: return
 for state: String in ["normal","focus"]: button.add_theme_stylebox_override(state,skin("ui_btn_"+kind) if state == "normal" else box(Color(0,0,0,0)))
 button.add_theme_stylebox_override("hover",skin("ui_btn_"+kind+"_hover"))
 button.add_theme_stylebox_override("pressed",skin("ui_btn_"+kind+"_pressed"))
 for state: String in ["normal","hover","pressed"]:
  var style: StyleBoxTexture = button.get_theme_stylebox(state) as StyleBoxTexture
  style.content_margin_top = 5
  style.content_margin_bottom = 5
 if kind == "buy":
  for color_name: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: button.add_theme_color_override(color_name,Color("2a1606"))
# Older callers pass a color; map it to the closest role.
static func button_color(button: Button, color: Color) -> void:
 var hue: float = color.h*360.0
 if color.s < 0.25: role(button,"neutral")
 elif hue >= 90.0 and hue < 170.0: role(button,"go")
 elif hue >= 170.0 and hue < 250.0: role(button,"info")
 elif hue >= 250.0 and hue < 320.0: role(button,"skip")
 elif hue >= 30.0 and hue < 70.0: role(button,"buy")
 else: role(button,"danger")
# Edition shimmer drawn over a Joker card (Aseprite overlays at the card's 70x94 size).
static func add_edition_overlay(card: Control, edition: String) -> void:
 if edition.is_empty(): return
 var overlay: TextureRect = TextureRect.new()
 overlay.name = "Edition"
 overlay.texture = texture("edition_"+edition)
 overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 card.add_child(overlay)
# Balatro-style keyword colours (v0.29): Mult red, Candys blue, money gold. Write numbers as
# "+4 Mult", "X1.5 Mult", "+30 Candys" or "$10" so the number takes the keyword's colour too.
const MULT_COLOR: String = "ff6a5a"
const CANDY_COLOR: String = "4cb4ff"
const MONEY_COLOR: String = "f5c045"
static var keyword_re: RegEx
static func rich(text: String) -> String:
 if keyword_re == null:
  keyword_re = RegEx.new()
  keyword_re.compile("([+\\-]?X?\\d+(?:\\.\\d+)?\\+? )?(Mult|Candys)|[+\\-]?\\$\\d+")
 var out: String = ""
 var last: int = 0
 for found: RegExMatch in keyword_re.search_all(text):
  out += text.substr(last,found.get_start()-last)
  var word: String = found.get_string()
  var color: String = MONEY_COLOR if word.contains("$") else (MULT_COLOR if word.ends_with("Mult") else CANDY_COLOR)
  out += "[color=#%s]%s[/color]" % [color,word]
  last = found.get_end()
 return out+text.substr(last)
# A wrapping rich-text label that shows coloured keywords.
static func rich_label(text: String, size: int = 22, color: Color = CREAM) -> RichTextLabel:
 var node: RichTextLabel = RichTextLabel.new()
 node.bbcode_enabled = true
 node.fit_content = true
 node.scroll_active = false
 node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 node.add_theme_font_override("normal_font",BODY_FONT)
 node.add_theme_font_size_override("normal_font_size",size)
 node.add_theme_color_override("default_color",color)
 node.text = rich(text)
 return node
