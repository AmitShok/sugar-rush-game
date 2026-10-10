extends Control
signal closed
signal use_requested(id: String)
var shop_mode: bool=false
var heading: Label
var summary: Label
var cards: HBoxContainer
var owned: HBoxContainer
var buttons: Dictionary={}
func _ready() -> void:
 z_index=190
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shade: TextureRect=TextureRect.new()
 shade.texture=UIStyle.texture("ui_shade")
 shade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 var panel: Panel=Panel.new()
 panel.position=Vector2(40,36)
 panel.size=Vector2(1072,652)
 panel.add_theme_stylebox_override("panel",UIStyle.skin("ui_panel"))
 add_child(panel)
 heading=UIStyle.label("CONSUMABLES",48)
 heading.position=Vector2(64,48)
 add_child(heading)
 summary=UIStyle.label("",24)
 summary.position=Vector2(64,104)
 add_child(summary)
 cards=HBoxContainer.new()
 cards.position=Vector2(64,150)
 cards.add_theme_constant_override("separation",16)
 add_child(cards)
 owned=HBoxContainer.new()
 owned.position=Vector2(64,546)
 owned.add_theme_constant_override("separation",16)
 add_child(owned)
 var back: Button=Button.new()
 back.name="Back"
 back.text="Back"
 back.position=Vector2(812,624)
 back.size=Vector2(276,44)
 back.add_theme_font_size_override("font_size",24)
 back.pressed.connect(func() -> void: closed.emit())
 add_child(back)
 GameManager.changed.connect(refresh)
 hide()
func open(in_shop: bool) -> void:
 shop_mode=in_shop
 show()
 refresh()
func refresh() -> void:
 if not visible: return
 summary.text="Held %s / 2 | %s" % [GameManager.consumables.size(),("Cash: "+UIStyle.money(GameManager.gummies)+" | Single-use cards; no Joker slots") if shop_mode else "Choose a card to use. Unused cards carry to the next round."]
 for row: Control in [cards,owned]:
  for child: Node in row.get_children():
   row.remove_child(child)
   child.queue_free()
 buttons.clear()
 var ids: Array=ConsumableCatalog.ITEMS.keys() if shop_mode else GameManager.consumables.duplicate()
 if ids.is_empty(): cards.add_child(UIStyle.label("No cards held. Buy consumables in the shop.",24))
 for id: String in ids:
  var item: Dictionary=ConsumableCatalog.ITEMS[id]
  var column: VBoxContainer=VBoxContainer.new()
  column.custom_minimum_size=Vector2(244,370)
  column.add_theme_constant_override("separation",8)
  cards.add_child(column)
  var title: Label=UIStyle.label(item.name,24,UIStyle.MINT)
  title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  column.add_child(title)
  var icon: TextureRect=TextureRect.new()
  icon.texture=UIStyle.texture(item.art)
  icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.custom_minimum_size=Vector2(244,141)
  column.add_child(icon)
  var description: Label=UIStyle.label(item.description,22)
  description.custom_minimum_size=Vector2(244,144)
  description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  column.add_child(description)
  var button: Button=Button.new()
  button.text=("Buy "+UIStyle.money(item.price)) if shop_mode else "Use"
  button.custom_minimum_size=Vector2(244,42)
  button.add_theme_font_size_override("font_size",24)
  if shop_mode:
   button.disabled=GameManager.consumables.size()>=2 or GameManager.gummies<item.price
   button.tooltip_text="Inventory full. Use or discard a held card." if GameManager.consumables.size()>=2 else ("Need %s more cash." % UIStyle.money(item.price-GameManager.gummies) if GameManager.gummies<item.price else "Cash after purchase: "+UIStyle.money(GameManager.gummies-item.price))
   button.pressed.connect(func() -> void: GameManager.buy_consumable(id))
  else: button.pressed.connect(func() -> void: use_requested.emit(id))
  column.add_child(button)
  buttons[id]=button
 if shop_mode:
  for i: int in range(GameManager.consumables.size()):
   var discard: Button=Button.new()
   discard.text="Discard "+ConsumableCatalog.ITEMS[GameManager.consumables[i]].name
   discard.custom_minimum_size=Vector2(420,42)
   discard.add_theme_font_size_override("font_size",24)
   discard.tooltip_text="Discard this held card to free a slot. No refund."
   discard.pressed.connect(GameManager.discard_consumable.bind(i))
   owned.add_child(discard)
