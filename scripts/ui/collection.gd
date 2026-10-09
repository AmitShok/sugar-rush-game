extends Control
signal closed
const PAGE_SIZE: int = 6
var page: int = 0
var selected: JokerData
var grid: GridContainer
var page_label: Label
var previous: Button
var next: Button
var back: Button
var portrait: TextureRect
var title: Label
var category: Label
var description: Label
var card_buttons: Array[TextureButton] = []
func _ready() -> void:
 z_index=180
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shade: TextureRect=TextureRect.new()
 shade.texture=UIStyle.texture("ui_shade")
 shade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 var panel: Panel=Panel.new()
 panel.position=Vector2(42,28)
 panel.size=Vector2(1068,664)
 panel.add_theme_stylebox_override("panel",UIStyle.skin("ui_panel"))
 add_child(panel)
 var heading: Label=UIStyle.label("JOKER COLLECTION",48)
 heading.position=Vector2(70,44)
 add_child(heading)
 var count: Label=UIStyle.label("All %s Jokers | Select a card" % GameManager.config.jokers.size(),24)
 count.position=Vector2(70,96)
 add_child(count)
 grid=GridContainer.new()
 grid.columns=3
 grid.position=Vector2(70,134)
 grid.add_theme_constant_override("h_separation",14)
 grid.add_theme_constant_override("v_separation",10)
 add_child(grid)
 var detail: Panel=Panel.new()
 detail.position=Vector2(640,104)
 detail.size=Vector2(440,508)
 detail.add_theme_stylebox_override("panel",UIStyle.skin("ui_inset"))
 add_child(detail)
 portrait=TextureRect.new()
 portrait.position=Vector2(788,122)
 portrait.size=Vector2(140,188)
 portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 add_child(portrait)
 title=UIStyle.label("",32,UIStyle.MINT)
 title.position=Vector2(660,326)
 title.size=Vector2(400,72)
 title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(title)
 category=UIStyle.label("",24,UIStyle.MUTED)
 category.position=Vector2(660,398)
 add_child(category)
 description=UIStyle.label("",24)
 description.position=Vector2(660,440)
 description.size=Vector2(400,150)
 description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(description)
 previous=make_button("Previous",Vector2(70,632),Vector2(158,42))
 previous.pressed.connect(turn_page.bind(-1))
 page_label=UIStyle.label("",24)
 page_label.position=Vector2(240,640)
 page_label.size.x=160
 page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 add_child(page_label)
 next=make_button("Next",Vector2(414,632),Vector2(158,42))
 next.pressed.connect(turn_page.bind(1))
 back=make_button("Back to Menu",Vector2(780,632),Vector2(300,42))
 back.pressed.connect(func() -> void: closed.emit())
 visible=false
func make_button(text: String,position_value: Vector2,dimensions: Vector2) -> Button:
 var button: Button=Button.new()
 button.text=text
 button.position=position_value
 button.size=dimensions
 button.add_theme_font_size_override("font_size",24)
 add_child(button)
 return button
func open() -> void:
 page=0
 refresh()
 visible=true
func turn_page(direction: int) -> void:
 page=clampi(page+direction,0,page_count()-1)
 refresh()
func page_count() -> int:
 return ceili(GameManager.config.jokers.size()/float(PAGE_SIZE))
func refresh() -> void:
 for child: Node in grid.get_children():
  grid.remove_child(child)
  child.queue_free()
 card_buttons.clear()
 var items: Array[JokerData]=GameManager.config.jokers
 for i: int in range(page*PAGE_SIZE,mini((page+1)*PAGE_SIZE,items.size())):
  var item: JokerData=items[i]
  var column: VBoxContainer=VBoxContainer.new()
  column.custom_minimum_size=Vector2(172,234)
  column.add_theme_constant_override("separation",2)
  grid.add_child(column)
  var card: TextureButton=TextureButton.new()
  card.texture_normal=item.icon
  card.ignore_texture_size=true
  card.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED
  card.custom_minimum_size=Vector2(172,188)
  card.tooltip_text=item.display_name
  card.pressed.connect(inspect.bind(item))
  card.focus_entered.connect(inspect.bind(item))
  column.add_child(card)
  card_buttons.append(card)
  var name_label: Label=UIStyle.label(item.display_name,24)
  name_label.custom_minimum_size=Vector2(172,44)
  name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  column.add_child(name_label)
 page_label.text="%s / %s" % [page+1,page_count()]
 previous.disabled=page==0
 next.disabled=page==page_count()-1
 inspect(items[page*PAGE_SIZE])
func inspect(item: JokerData) -> void:
 selected=item
 portrait.texture=item.icon
 title.text=item.display_name
 var type: String={"Three":"Exactly 3","Four":"4+ match","Five":"5+ match"}.get(item.category,item.category)
 category.text="%s | Shop price %s" % [type,UIStyle.money(item.price)]
 description.text=item.description
