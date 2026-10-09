extends Control
signal continue_requested
var selected: JokerData
var selected_owned: bool = false
var offer_buttons: Dictionary = {}
var card_buttons: Dictionary = {}
var upgrades_open: bool = false
var upgrade_rows: VBoxContainer
var upgrade_buttons: Array[Button] = []
var joker_tab: Button
var upgrade_tab: Button
func make_tab(text: String, x: float) -> Button:
 var button: Button=Button.new()
 button.text=text
 button.position=Vector2(x,44)
 button.size=Vector2(290,40)
 button.add_theme_font_size_override("font_size",24)
 add_child(button)
 return button
func show_upgrades(open: bool) -> void:
 upgrades_open=open
 refresh()
func refresh_upgrades() -> void:
 $Offers.visible=not upgrades_open
 upgrade_rows.visible=upgrades_open
 $Actions/Reroll.visible=not upgrades_open
 joker_tab.disabled=not upgrades_open
 upgrade_tab.disabled=upgrades_open
 if not upgrades_open:
  $Details/Status.position.y=78
  $Details/Description.add_theme_font_size_override("font_size",24)
  return
 for child: Node in upgrade_rows.get_children():
  upgrade_rows.remove_child(child)
  child.queue_free()
 upgrade_buttons.clear()
 for color: int in range(GameManager.config.candies.size()):
  var candy: CandyData=GameManager.config.candies[color]
  var row: HBoxContainer=HBoxContainer.new()
  row.custom_minimum_size=Vector2(596,40)
  row.add_theme_constant_override("separation",6)
  upgrade_rows.add_child(row)
  var icon: TextureRect=TextureRect.new()
  icon.texture=candy.texture
  icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.custom_minimum_size=Vector2(36,36)
  row.add_child(icon)
  var label: Label=UIStyle.label(candy.display_name,24)
  label.custom_minimum_size.x=220
  label.tooltip_text="Level %s | +%s Candys from upgrades" % [GameManager.candy_level(color),GameManager.candy_bonus(color)]
  row.add_child(label)
  var value: Label=UIStyle.label("%s > %s" % [GameManager.candy_value(color),GameManager.candy_value(color)+GameManager.upgrade_gain(color)],24,UIStyle.MINT)
  value.custom_minimum_size.x=142
  row.add_child(value)
  var buy: Button=Button.new()
  var cost: int=GameManager.upgrade_cost(color)
  buy.text="Buy %s" % UIStyle.money(cost)
  buy.custom_minimum_size=Vector2(164,40)
  buy.add_theme_font_size_override("font_size",24)
  buy.disabled=GameManager.gummies<cost
  buy.tooltip_text="+%s Candys each | Level %s > %s\n%s" % [GameManager.upgrade_gain(color),GameManager.candy_level(color),GameManager.candy_level(color)+1,("Need %s more cash" % UIStyle.money(cost-GameManager.gummies) if buy.disabled else "Cash after purchase: "+UIStyle.money(GameManager.gummies-cost))]
  buy.pressed.connect(purchase_upgrade.bind(color))
  row.add_child(buy)
  upgrade_buttons.append(buy)
 $Details.show()
 $Details/Name.text="Candy values | This run only"
 $Details/Description.add_theme_font_size_override("font_size",22)
 $Details/Description.text="Current > next Candys. Buys stack; no slots.\nGold and caramel get the bonus too."
 $Details/Status.text="Each type starts at $4; its next price rises by $2 per buy."
 $Details/Status.position.y=80
 $Details/Action.hide()
func purchase_upgrade(color: int) -> void:
 var cost: int=GameManager.upgrade_cost(color)
 if GameManager.buy_candy_upgrade(color):
  $Receipt.text="%s: +%s Candys | Level %s | -%s" % [GameManager.config.candies[color].display_name,GameManager.upgrade_gain(color),GameManager.candy_level(color),UIStyle.money(cost)]

func _ready() -> void:
 joker_tab=make_tab("Jokers",188)
 upgrade_tab=make_tab("Candy Upgrades",488)
 joker_tab.pressed.connect(show_upgrades.bind(false))
 upgrade_tab.pressed.connect(show_upgrades.bind(true))
 upgrade_rows=VBoxContainer.new()
 upgrade_rows.position=Vector2(188,92)
 upgrade_rows.add_theme_constant_override("separation",3)
 add_child(upgrade_rows)
 upgrade_rows.hide()
 GameManager.shop_opened.connect(func() -> void: upgrades_open=false)
 GameManager.changed.connect(refresh)
 $Actions/Reroll.pressed.connect(reroll)
 $Actions/Continue.pressed.connect(func() -> void: continue_requested.emit())
 $Details/Action.pressed.connect(detail_action)
 UIStyle.button_color($Actions/Reroll,Color("388e63"))
 UIStyle.button_color($Actions/Continue,Color("b7473b"))
 $Wallet.hide()
 $Tip.hide()
 $Details.add_theme_stylebox_override("panel",UIStyle.box(Color("172c32"),Color("6c8585"),2))
func reason(item: JokerData) -> String:
 if GameManager.jokers.has(item.id): return "Already owned"
 if GameManager.jokers.equipped.size() >= GameManager.jokers.capacity: return "No Joker slots left. Select an owned card above to sell it."
 if GameManager.gummies < item.price: return "Need %s more cash." % UIStyle.money(item.price-GameManager.gummies)
 return "Cash after purchase: %s" % UIStyle.money(GameManager.gummies-item.price)
func inspect(item: JokerData, owned: bool = false) -> void:
 if upgrades_open: show_upgrades(false)
 selected = item
 selected_owned = owned
 update_details()
func inspect_owned(item: JokerData) -> void:
 if GameManager.state == "shop": inspect(item,true)
func update_details() -> void:
 $Details.visible = selected != null
 if selected == null:
  $Details/Name.text = "Choose a Joker"
  $Details/Description.text = "Select a shop card to read its effect. Select an owned Joker above to sell it."
  $Details/Status.text = "Cash stays with you between rounds."
  $Details/Action.visible = false
  return
 $Details/Name.text = selected.display_name
 $Details/Description.text = selected.description
 $Details/Status.text = "Sell value: %s   |   Cash after sale: %s" % [UIStyle.money(selected.price/2),UIStyle.money(GameManager.gummies+selected.price/2)] if selected_owned else reason(selected)
 $Details/Action.visible = true
 $Details/Action.text = "Sell +%s" % UIStyle.money(selected.price/2) if selected_owned else "Buy %s" % UIStyle.money(selected.price)
 $Details/Action.disabled = not (selected in GameManager.jokers.equipped) if selected_owned else not can_buy(selected)
func can_buy(item: JokerData) -> bool:
 return item in GameManager.offers and GameManager.gummies >= item.price and GameManager.jokers.can_add(item)
func detail_action() -> void:
 if selected_owned:
  var item: JokerData = selected
  selected = null
  GameManager.sell(item)
  $Receipt.text = "Sold %s: +%s" % [item.display_name,UIStyle.money(item.price/2)]
 else: purchase(selected)
func purchase(item: JokerData) -> void:
 if GameManager.buy(item):
  selected = item
  selected_owned = true
  update_details()
  $Receipt.text = "Bought %s: -%s" % [item.display_name,UIStyle.money(item.price)]
func reroll() -> void:
 var cost: int = GameManager.reroll_cost
 if GameManager.gummies < cost: return
 selected = null
 GameManager.reroll()
 $Receipt.text = "New stock: -%s" % UIStyle.money(cost)
func refresh() -> void:
 if GameManager.state != "shop": return
 $Actions/Continue.text = "Next:\n"+("Boss" if (GameManager.round_index+1)%3==2 else ("Small" if (GameManager.round_index+1)%3==0 else "Big"))
 $Heading.text = "SHOP"
 $Wallet.text = "Available cash: %s" % UIStyle.money(GameManager.gummies)
 $Receipt.text = "Round reward +%s" % UIStyle.money(GameManager.last_award)
 $Receipt.tooltip_text = GameManager.last_summary
 $Actions/Reroll.text = "Reroll\n%s" % UIStyle.money(GameManager.reroll_cost)
 $Actions/Reroll.disabled = GameManager.gummies < GameManager.reroll_cost
 $Actions/Reroll.tooltip_text = "Replace unsold shop cards. Costs %s." % UIStyle.money(GameManager.reroll_cost)
 for child: Node in $Offers.get_children():
  $Offers.remove_child(child)
  child.queue_free()
 offer_buttons.clear()
 card_buttons.clear()
 for slot: int in range(4):
  var column: VBoxContainer = VBoxContainer.new()
  column.custom_minimum_size = Vector2(140,244)
  column.add_theme_constant_override("separation",12)
  $Offers.add_child(column)
  if slot >= GameManager.offers.size():
   var sold: Label = UIStyle.label("SOLD",32,UIStyle.MUTED)
   sold.custom_minimum_size = Vector2(140,266)
   sold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   sold.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
   column.add_child(sold)
   continue
  var item: JokerData = GameManager.offers[slot]
  var card: TextureButton = TextureButton.new()
  card.texture_normal = item.icon
  card.texture_hover = item.icon
  card.custom_minimum_size = Vector2(140,188)
  card.ignore_texture_size = true
  card.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
  card.tooltip_text = item.display_name
  card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  card.pressed.connect(inspect.bind(item,false))
  card.focus_entered.connect(inspect.bind(item,false))
  column.add_child(card)
  card_buttons[item.id] = card
  var buy: Button = Button.new()
  buy.text = "Buy %s" % UIStyle.money(item.price)
  buy.custom_minimum_size = Vector2(140,42)
  buy.add_theme_font_size_override("font_size",24)
  buy.disabled = not can_buy(item)
  buy.tooltip_text = reason(item)
  buy.pressed.connect(purchase.bind(item))
  column.add_child(buy)
  offer_buttons[item.id] = buy
 if selected != null and selected not in GameManager.offers and selected not in GameManager.jokers.equipped: selected = null
 update_details()
 refresh_upgrades()
