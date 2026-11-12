extends Control
signal consumables_requested
signal continue_requested
var selected: JokerData
var selected_owned: bool = false
var offer_buttons: Dictionary = {}
var card_buttons: Dictionary = {}
# Shop page: "jokers", "candies" (candy upgrades) or "recipes" (recipe levels).
var page: String = "jokers"
var upgrades_open: bool:
 get: return page == "candies"
var upgrade_rows: VBoxContainer
var candy_rows: Array[HBoxContainer] = []
var recipe_rows: Dictionary = {}
var pack_row: HBoxContainer
var pack_buttons: Array[Button] = []
var pack_tab: Button
var joker_tab: Button
var upgrade_tab: Button
var recipe_tab: Button
var shaker_buy: Button
var move_left: Button
var move_right: Button
func make_tab(text: String, x: float) -> Button:
 var button: Button=Button.new()
 button.text=text
 button.position=Vector2(x,44)
 button.size=Vector2(142,40)
 button.add_theme_font_size_override("font_size",24)
 add_child(button)
 return button
func show_upgrades(open: bool) -> void:
 show_page("candies" if open else "jokers")
func show_page(value: String) -> void:
 page=value
 refresh()
func clear_rows() -> void:
 for child: Node in upgrade_rows.get_children():
  upgrade_rows.remove_child(child)
  child.queue_free()
 candy_rows.clear()
 recipe_rows.clear()
func refresh_upgrades() -> void:
 var on_jokers: bool=page=="jokers"
 $Offers.visible=on_jokers
 upgrade_rows.visible=page in ["candies","recipes"]
 pack_row.visible=page=="packs"
 pack_tab.disabled=page=="packs"
 pack_tab.text="Packs (%s)" % GameManager.pack_offers.size() if not GameManager.pack_offers.is_empty() else "Packs"
 $Actions/Reroll.visible=on_jokers
 joker_tab.disabled=page=="jokers"
 upgrade_tab.disabled=page=="candies"
 recipe_tab.disabled=page=="recipes"
 if on_jokers:
  $Details/Status.position.y=78
  $Details/Description.add_theme_font_size_override("font_size",24)
  return
 clear_rows()
 move_left.hide()
 move_right.hide()
 if page=="packs":
  refresh_packs()
  return
 if page=="recipes":
  refresh_recipes()
  return
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
  var label: Label=UIStyle.label("%s  Lv %s" % [candy.display_name,GameManager.candy_level(color)],24)
  label.custom_minimum_size.x=262
  label.tooltip_text="Level %s | +%s Candys from upgrades" % [GameManager.candy_level(color),GameManager.candy_bonus(color)]
  label.mouse_filter=Control.MOUSE_FILTER_STOP
  row.add_child(label)
  var value: Label=UIStyle.label("%s > %s" % [GameManager.candy_value(color),GameManager.candy_value(color)+GameManager.upgrade_gain(color)],24,UIStyle.MINT)
  value.custom_minimum_size.x=136
  row.add_child(value)
  # Since v0.28 candy upgrades come only from Candy Packs; this page shows values.
  var source: Label=UIStyle.label("From packs",20,UIStyle.MUTED)
  source.custom_minimum_size.x=140
  source.tooltip_text="Next level: +%s Candys each. Find Candy Packs on the Packs tab." % GameManager.upgrade_gain(color)
  source.mouse_filter=Control.MOUSE_FILTER_STOP
  row.add_child(source)
  candy_rows.append(row)
 $Details.hide() # v0.29: rows explain themselves; no always-on explainer
 $Details/Name.text="Candy values | This run only"
 $Details/Description.add_theme_font_size_override("font_size",22)
 $Details/Description.text="Current > next Candys; gold and caramel get it too.\nUpgrade candies with Candy Packs (Packs tab)."
 $Details/Status.text="Each Candy Pack card adds half the type's base value."
 $Details/Status.position.y=80
 $Details/Action.hide()
func refresh_recipes() -> void:
 for id: String in RecipeCatalog.ORDER:
  var info: Dictionary=RecipeCatalog.ITEMS[id]
  var lvl: int=GameManager.recipe_level(id)
  var row: HBoxContainer=HBoxContainer.new()
  row.custom_minimum_size=Vector2(596,40)
  row.add_theme_constant_override("separation",6)
  upgrade_rows.add_child(row)
  var label: Label=UIStyle.label("%s  Lv %s" % [info.name,lvl],24)
  label.custom_minimum_size.x=210
  label.tooltip_text=info.shape
  label.mouse_filter=Control.MOUSE_FILTER_STOP
  row.add_child(label)
  var value: Label=UIStyle.label("%sx%s > %sx%s" % [RecipeCatalog.candys(id,lvl),RecipeCatalog.mult(id,lvl),RecipeCatalog.candys(id,lvl+1),RecipeCatalog.mult(id,lvl+1)],24,UIStyle.MINT)
  value.custom_minimum_size.x=226
  row.add_child(value)
  var source: Label=UIStyle.label("From packs",20,UIStyle.MUTED)
  source.custom_minimum_size.x=140
  source.tooltip_text="%s\nNext level: +%s Candys, +%s Mult. Find Recipe Packs on the Packs tab." % [info.shape,info.level_candys,info.level_mult]
  source.mouse_filter=Control.MOUSE_FILTER_STOP
  row.add_child(source)
  recipe_rows[id]=row
 $Details.hide() # v0.29: rows explain themselves; no always-on explainer
 $Details/Name.text="Recipes | This run only"
 $Details/Description.add_theme_font_size_override("font_size",22)
 $Details/Description.text="Each match type adds its own Candys and Mult.\nRows show Candys x Mult: now > next level."
 $Details/Status.text="Level recipes with Recipe Packs, Cookbook Tags and rare cards."
 $Details/Status.position.y=80
 $Details/Action.hide()
func refresh_packs() -> void:
 for child: Node in pack_row.get_children():
  pack_row.remove_child(child)
  child.queue_free()
 pack_buttons.clear()
 for slot: int in range(2):
  var column: VBoxContainer=VBoxContainer.new()
  column.custom_minimum_size=Vector2(180,250)
  column.add_theme_constant_override("separation",6)
  pack_row.add_child(column)
  if slot >= GameManager.pack_offers.size():
   var gone: Label=UIStyle.label("OPENED",32,UIStyle.MUTED)
   gone.custom_minimum_size=Vector2(180,250)
   gone.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
   gone.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
   column.add_child(gone)
   continue
  var pack: Dictionary=GameManager.pack_offers[slot]
  var title: Label=UIStyle.label(PackCatalog.kind_name(pack),20,UIStyle.MINT)
  title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  column.add_child(title)
  var art: TextureRect=TextureRect.new()
  art.texture=UIStyle.texture(PackCatalog.ITEMS[pack.kind].art)
  art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  art.custom_minimum_size=Vector2(180,150)
  CardTilt.attach(art)
  art.tooltip_text=PackCatalog.ITEMS[pack.kind].blurb
  art.mouse_filter=Control.MOUSE_FILTER_STOP
  if pack.jumbo:
   var jumbo: TextureRect=TextureRect.new()
   jumbo.texture=UIStyle.texture("pack_jumbo")
   jumbo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
   jumbo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   jumbo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
   jumbo.mouse_filter=Control.MOUSE_FILTER_IGNORE
   art.add_child(jumbo)
  column.add_child(art)
  var price: int=PackCatalog.price(pack)
  var open: Button=Button.new()
  open.text="Open FREE" if price==0 else "Open %s" % UIStyle.money(price)
  open.custom_minimum_size=Vector2(180,42)
  open.add_theme_font_size_override("font_size",24)
  open.disabled=not GameManager.can_open_pack(slot)
  UIStyle.role(open,"buy")
  open.tooltip_text="%s\nShows %s cards, keep %s." % [PackCatalog.ITEMS[pack.kind].blurb,PackCatalog.size(pack),PackCatalog.picks(pack)]+("" if not open.disabled else "\nNeed %s more cash." % UIStyle.money(price-GameManager.gummies))
  open.pressed.connect(func() -> void: GameManager.open_pack(slot))
  column.add_child(open)
  pack_buttons.append(open)
 $Details.hide() # v0.29: rows explain themselves; no always-on explainer
 $Details/Name.text="Booster packs"
 $Details/Description.add_theme_font_size_override("font_size",22)
 $Details/Description.text="Open a pack and keep the cards you want.\nNew packs each shop; rerolls keep them."
 $Details/Status.text="Joker, Recipe, Candy, Treat and rare Sugar Rush packs."
 $Details/Status.position.y=80
 $Details/Action.hide()

func _ready() -> void:
 shaker_buy=Button.new()
 shaker_buy.name="BuyShaker"
 shaker_buy.position=Vector2(188,0)
 shaker_buy.size=Vector2(590,38)
 shaker_buy.add_theme_font_size_override("font_size",24)
 shaker_buy.icon=UIStyle.texture("sugar_shaker")
 shaker_buy.expand_icon=true
 shaker_buy.add_theme_constant_override("icon_max_width",24)
 shaker_buy.pressed.connect(func() -> void: consumables_requested.emit())
 add_child(shaker_buy)
 joker_tab=make_tab("Jokers",188)
 pack_tab=make_tab("Packs",339)
 recipe_tab=make_tab("Recipes",641)
 upgrade_tab=make_tab("Candies",490)
 joker_tab.pressed.connect(show_upgrades.bind(false))
 upgrade_tab.pressed.connect(show_upgrades.bind(true))
 recipe_tab.pressed.connect(show_page.bind("recipes"))
 pack_tab.pressed.connect(show_page.bind("packs"))
 pack_row=HBoxContainer.new()
 pack_row.position=Vector2(188,92)
 pack_row.add_theme_constant_override("separation",24)
 add_child(pack_row)
 pack_row.hide()
 upgrade_rows=VBoxContainer.new()
 upgrade_rows.position=Vector2(188,92)
 upgrade_rows.add_theme_constant_override("separation",3)
 add_child(upgrade_rows)
 upgrade_rows.hide()
 GameManager.shop_opened.connect(func() -> void: page="jokers")
 GameManager.changed.connect(refresh)
 $Actions/Reroll.pressed.connect(reroll)
 $Actions/Continue.pressed.connect(func() -> void: continue_requested.emit())
 $Details/Action.pressed.connect(detail_action)
 # Owned Jokers can be reordered: they score left to right.
 move_left=Button.new()
 move_left.text="< Move"
 move_left.tooltip_text="Move this Joker left. Jokers score left to right."
 move_left.position=Vector2(598,66)
 move_left.size=Vector2(76,34)
 move_left.add_theme_font_size_override("font_size",18)
 move_left.pressed.connect(move_selected.bind(-1))
 $Details.add_child(move_left)
 move_right=Button.new()
 move_right.text="Move >"
 move_right.tooltip_text="Move this Joker right. Jokers score left to right."
 move_right.position=Vector2(678,66)
 move_right.size=Vector2(76,34)
 move_right.add_theme_font_size_override("font_size",18)
 move_right.pressed.connect(move_selected.bind(1))
 $Details.add_child(move_right)
 move_left.hide()
 move_right.hide()
 UIStyle.role($Actions/Reroll,"buy")
 UIStyle.role($Details/Action,"buy")
 UIStyle.role(shaker_buy,"info")
 for tab: Button in [joker_tab,pack_tab,upgrade_tab,recipe_tab,move_left,move_right]: UIStyle.role(tab,"neutral")
 UIStyle.role($Actions/Continue,"go")
 $Wallet.hide()
 $Tip.hide()
 $Details.add_theme_stylebox_override("panel",UIStyle.box(Color("172c32"),Color("6c8585"),2))
func reason(item: JokerData) -> String:
 if GameManager.jokers.has(item.id): return "Already owned"
 if GameManager.jokers.equipped.size() >= GameManager.jokers.capacity: return "No Joker slots left. Select an owned card above to sell it."
 if GameManager.gummies < GameManager.offer_price(item): return "Need %s more" % UIStyle.money(GameManager.offer_price(item)-GameManager.gummies)
 return ("FREE  |  " if GameManager.offer_price(item)==0 else "")+"After: %s" % UIStyle.money(GameManager.gummies-GameManager.offer_price(item))
func inspect(item: JokerData, owned: bool = false) -> void:
 if page != "jokers": show_page("jokers")
 selected = item
 selected_owned = owned
 update_details()
func inspect_owned(item: JokerData) -> void:
 if GameManager.state == "shop": inspect(item,true)
func update_details() -> void:
 $Details.visible = selected != null
 if selected == null:
  show_rarity(null)
  $Details/Name.text = "Choose a Joker"
  $Details/Description.text = "Select a shop card to read its effect. Select an owned Joker above to sell it."
  $Details/Status.text = "Cash stays with you between rounds."
  $Details/Action.visible = false
  move_left.hide()
  move_right.hide()
  return
 $Details/Name.text = GameManager.joker_title(selected,not selected_owned)
 show_rarity(selected)
 describe(selected.description)
 # Edition effect and live growth go on the status line so the description keeps its two lines.
 var edition: String = GameManager.jokers.edition(selected.id) if selected_owned else String(GameManager.offer_editions.get(selected.id,""))
 var extras: PackedStringArray = []
 if not edition.is_empty(): extras.append(EditionCatalog.ITEMS[edition].effect)
 if selected_owned and not GameManager.scaling_status(selected.id).is_empty(): extras.append(GameManager.scaling_status(selected.id))
 var prefix: String = " | ".join(extras)+"  |  " if not extras.is_empty() else ""
 $Details/Status.text = prefix+("Sell %s  |  After: %s" % [UIStyle.money(GameManager.sell_value(selected)),UIStyle.money(GameManager.gummies+GameManager.sell_value(selected))] if selected_owned else reason(selected))
 $Details/Action.visible = true
 $Details/Action.text = "Sell +%s" % UIStyle.money(GameManager.sell_value(selected)) if selected_owned else ("Take free" if GameManager.offer_price(selected)==0 else "Buy %s" % UIStyle.money(GameManager.offer_price(selected)))
 $Details/Action.disabled = not (selected in GameManager.jokers.equipped) if selected_owned else not can_buy(selected)
 var index: int = GameManager.jokers.equipped.find(selected)
 move_left.visible = selected_owned and index >= 0
 move_right.visible = selected_owned and index >= 0
 move_left.disabled = index <= 0
 move_right.disabled = index < 0 or index >= GameManager.jokers.equipped.size()-1
func can_buy(item: JokerData) -> bool:
 return item in GameManager.offers and GameManager.gummies >= GameManager.offer_price(item) and GameManager.jokers.can_add(item)
func detail_action() -> void:
 if selected_owned:
  var item: JokerData = selected
  selected = null
  var refund: int = GameManager.sell_value(item)
  GameManager.sell(item)
  $Receipt.text = "Sold %s: +%s" % [item.display_name,UIStyle.money(refund)]
 else: purchase(selected)
func purchase(item: JokerData) -> void:
 var paid: int = GameManager.offer_price(item)
 if GameManager.buy(item):
  selected = item
  selected_owned = true
  update_details()
  $Receipt.text = "Bought %s: -%s" % [item.display_name,UIStyle.money(paid)]
func reroll() -> void:
 var cost: int = GameManager.current_reroll_cost()
 if GameManager.gummies < cost: return
 selected = null
 GameManager.reroll()
 $Receipt.text = "New stock: -%s" % UIStyle.money(cost)
func refresh() -> void:
 if GameManager.state != "shop": return
 # After a skip the shop is closed until the next cleared round.
 var closed: bool = GameManager.shop_closed
 if closed: page = "jokers"
 for control: Control in [shaker_buy,joker_tab,pack_tab,upgrade_tab,recipe_tab]: control.visible = not closed
 shaker_buy.text="Items  %s / 2" % GameManager.consumables.size()
 shaker_buy.disabled=false
 shaker_buy.tooltip_text="Two random cards per shop refresh. Each offer can be bought once; hold up to two."
 $Actions/Continue.text = "Next:\n"+("Boss" if (GameManager.round_index+1)%3==2 else ("Small" if (GameManager.round_index+1)%3==0 else "Big"))
 $Heading.text = "SKIPPED" if GameManager.shop_closed else "SHOP"
 $Wallet.text = "Available cash: %s" % UIStyle.money(GameManager.gummies)
 if GameManager.last_summary.begins_with("Skipped"): $Receipt.text = GameManager.last_summary
 else: $Receipt.text = "Round reward +%s" % UIStyle.money(GameManager.last_award)+("  (interest %s)" % UIStyle.money(GameManager.last_interest) if GameManager.last_interest>0 else "")
 $Receipt.tooltip_text = GameManager.last_summary
 $Actions/Reroll.text = "Reroll\n"+("Free x%s" % GameManager.free_rerolls if GameManager.free_rerolls > 0 else UIStyle.money(GameManager.reroll_cost))
 $Actions/Reroll.disabled = GameManager.gummies < GameManager.current_reroll_cost()
 $Actions/Reroll.tooltip_text = "Replace unsold shop cards. Costs %s." % UIStyle.money(GameManager.current_reroll_cost())
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
   var sold: Label = UIStyle.label("CLOSED" if GameManager.shop_closed else "SOLD",32,UIStyle.MUTED)
   sold.custom_minimum_size = Vector2(140,266)
   sold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   sold.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
   column.add_child(sold)
   continue
  var item: JokerData = GameManager.offers[slot]
  var card: TextureButton = TextureButton.new()
  card.texture_normal = item.icon
  CardTilt.attach(card)
  UIStyle.add_edition_overlay(card,String(GameManager.offer_editions.get(item.id,"")))
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
  buy.text = "FREE" if GameManager.offer_price(item)==0 else "Buy %s" % UIStyle.money(GameManager.offer_price(item))
  buy.custom_minimum_size = Vector2(140,42)
  buy.add_theme_font_size_override("font_size",24)
  buy.disabled = not can_buy(item)
  UIStyle.role(buy,"buy")
  buy.tooltip_text = reason(item)
  buy.pressed.connect(purchase.bind(item))
  column.add_child(buy)
  offer_buttons[item.id] = buy
 if selected != null and selected not in GameManager.offers and selected not in GameManager.jokers.equipped: selected = null
 update_details()
 refresh_upgrades()
 if GameManager.shop_closed:
  $Actions/Reroll.visible = false
  $Details.show()
  $Details/Name.text = "Shop skipped"
  describe("Skipped for a Tag: no shop this time.")
  $Details/Status.text = ""
  $Details/Action.hide()
func move_selected(delta: int) -> void:
 if selected != null and selected_owned and GameManager.move_joker(selected,delta):
  $Receipt.text = "Moved %s %s" % [selected.display_name,"left" if delta < 0 else "right"]
# Joker effect text with Balatro-style coloured keywords (v0.29). The plain Label stays in place
# (invisible) for layout and tests; a rich-text twin draws the coloured version on top.
var rich_description: RichTextLabel
func describe(text: String) -> void:
 $Details/Description.text = text
 if rich_description == null:
  rich_description = UIStyle.rich_label("",24)
  rich_description.name = "RichDescription"
  rich_description.position = $Details/Description.position
  rich_description.size = $Details/Description.size
  $Details.add_child(rich_description)
  $Details/Description.self_modulate.a = 0.0
 rich_description.add_theme_font_size_override("normal_font_size",$Details/Description.get_theme_font_size("font_size"))
 rich_description.text = UIStyle.rich(text)
# Rarity pill placed right after the selected Joker's name.
func show_rarity(item: JokerData) -> void:
 var old: Node = $Details.get_node_or_null("RarityPill")
 if old:
  $Details.remove_child(old)
  old.queue_free()
 if item == null: return
 var pill: Control = UIStyle.rarity_pill(item.rarity)
 var name_label: Label = $Details/Name
 var font: Font = name_label.get_theme_font("font")
 var width: float = font.get_string_size(name_label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,name_label.get_theme_font_size("font_size")).x
 pill.position = Vector2(name_label.position.x+minf(width,440.0)+12.0,6.0)
 $Details.add_child(pill)
