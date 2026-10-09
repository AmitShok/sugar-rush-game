class_name UIStyle
extends RefCounted
const INK: Color = Color("17262b")
const CREAM: Color = Color("fff8e7")
const MUTED: Color = Color("c4d0cc")
const PINK: Color = Color("ef6355")
const MINT: Color = Color("f5b957")
const BODY_FONT: Font = preload("res://assets/exported/readable_font.fnt")
const FONT: Font = preload("res://assets/exported/ui_font.fnt")
static var textures: Dictionary = {}
static func texture(name: String) -> Texture2D:
 if not textures.has(name): textures[name] = load("res://assets/exported/"+name+".png")
 return textures[name] as Texture2D
static func skin(name: String) -> StyleBoxTexture:
 var style: StyleBoxTexture = StyleBoxTexture.new()
 style.texture = texture(name)
 style.texture_margin_left = 6
 style.texture_margin_right = 6
 style.texture_margin_top = 6
 style.texture_margin_bottom = 6
 style.content_margin_left = 14
 style.content_margin_right = 14
 style.content_margin_top = 10
 style.content_margin_bottom = 10
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
 theme.set_color("font_shadow_color","Label",Color("132326"))
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
 theme.set_color("font_disabled_color","Button",Color("9caea5"))
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
 root.theme = theme
 preserve_headings(root)
static func preserve_headings(node: Node) -> void:
 if node is Label and node.get_theme_font_size("font_size") >= 32:
  node.add_theme_font_override("font",FONT)
 for child: Node in node.get_children(): preserve_headings(child)
static func label(text: String,size: int = 32,color: Color = CREAM) -> Label:
 var node: Label = Label.new()
 node.text = text
 node.add_theme_font_override("font",FONT if size >= 32 else BODY_FONT)
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
static func button_color(button: Button, color: Color) -> void:
 button.add_theme_stylebox_override("normal",box(color,color.lightened(0.2),2))
 button.add_theme_stylebox_override("hover",box(color.lightened(0.15),CREAM,2))
 button.add_theme_stylebox_override("pressed",box(color.darkened(0.2),CREAM,2))
