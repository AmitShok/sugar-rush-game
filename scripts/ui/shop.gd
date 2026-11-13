extends Control
signal consumables_requested
signal continue_requested
# v0.34: one Balatro-style shop row: two Jokers, then two booster packs, each with its own
# Buy/Open button. Reroll replaces the Jokers; packs stay until opened. Recipe and candy levels
# (earned from packs) moved off the shop floor into the Levels pop-up.
const JOKER_SLOTS: int = 2
var selected: JokerData
var selected_owned: bool = false
var offer_buttons: Dictionary = {}
var card_buttons: Dictionary = {}
var pack_buttons: Array[Button] = []
var pack_cards: Array[Control] = []
var levels_panel: PanelContainer
var upgrade_rows: VBoxContainer
var candy_rows: Array[HBoxContainer] = []
var recipe_rows: Dictionary = {}
var levels_button: Button
var levels_close: Button
var shaker_buy: Button
var joker_heading: Label
var pack_heading: Label
var move_left: Button
var move_right: Button
var levels_open: bool:
 get: return levels_panel != null and levels_panel.visible

func _ready() -> void:
 shaker_buy=Button.new()
 shaker_buy.name="BuyShaker"
 shaker_buy.position=Vector2(188,0)
 shaker_buy.size=Vector2(290,38)
 shaker_buy.add_theme_font_size_override("font_size",24)
 shaker_buy.icon=UIStyle.texture("sugar_shaker")
 shaker_buy.expand_icon=true
 shaker_buy.add_theme_constant_override("icon_max_width",24)
 shaker_buy.pressed.connect(func() -> void: consumables_requested.emit())
 add_child(shaker_buy)
 levels_button=Button.new()
 levels_button.name="LevelsButton"
 levels_button.text="Levels"
 levels_button.position=Vector2(488,0)
 levels_button.size=Vector2(290,38)
 levels_button.add_theme_font_size_override("font_size",24)
 levels_button.tooltip_text="Recipe and candy levels for this run"
 levels_button.pressed.connect(open_levels)
 add_child(levels_button)
 joker_heading=section_heading("JOKERS",188)
 pack_heading=section_heading("BOOSTER PACKS",492)
 build_levels_panel()
 GameManager.changed.connect(refresh)
 GameManager.shop_opened.connect(close_levels)
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
 UIStyle.role(levels_button,"info")
 for button: Button in [move_left,move_right]: UIStyle.role(button,"neutral")
 UIStyle.role($Actions/Continue,"go")
 $Offers.add_theme_constant_override("separation",12)
 $Wallet.hide()
 $Tip.hide()
 $Details.add_theme_stylebox_override("panel",UIStyle.box(Color("172c32"),Color("6c8585"),2))

func section_heading(text: String, x: float) -> Label:
 var heading: Label=UIStyle.label(text,24,UIStyle.MUTED)
 heading.position=Vector2(x,50)
 heading.size=Vector2(292,32)
 heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 heading.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(heading)
 return heading

# --- Levels pop-up (recipes and candy values; both level up from packs) ---
func build_levels_panel() -> void:
 levels_panel=PanelContainer.new()
 levels_panel.name="Levels"
 levels_panel.visible=false
 levels_panel.z_index=10
 # The shop sits at (352,194) on the canvas; centre the pop-up on the 1152 x 720 screen.
 levels_panel.position=Vector2(-112,-170)
 levels_panel.size=Vector2(680,0)
 levels_panel.add_theme_stylebox_override("panel",UIStyle.box(Color("172c32"),Color("6c8585"),2))
 add_child(levels_panel)
 var column: VBoxContainer=VBoxContainer.new()
 column.add_theme_constant_override("separation",4)
 levels_panel.add_child(column)
 upgrade_rows=VBoxContainer.new()
 upgrade_rows.add_theme_constant_override("separation",2)
 column.add_child(upgrade_rows)
 levels_close=Button.new()
 levels_close.text="Back to shop"
 levels_close.custom_minimum_size=Vector2(0,42)
 levels_close.add_theme_font_size_override("font_size",24)
 levels_close.pressed.connect(close_levels)
 UIStyle.role(levels_close,"neutral")
 column.add_child(levels_close)

func open_levels() -> void:
 refresh_levels()
 levels_panel.reset_size()
 levels_panel.show()
 levels_close.grab_focus()

func close_levels() -> void:
 if levels_panel: levels_panel.hide()

func clear_rows() -> void:
 for child: Node in upgrade_rows.get_children():
  upgrade_rows.remove_child(child)
  child.queue_free()
 candy_rows.clear()
 recipe_rows.clear()

func refresh_levels() -> void:
 clear_rows()
 var heading: Label=UIStyle.label("RECIPES  (Candys x Mult: now > next)",24,UIStyle.MINT)
 upgrade_rows.add_child(heading)
 for id: String in RecipeCatalog.ORDER:
  var info: Dictionary=RecipeCatalog.ITEMS[id]
  var lvl: int=GameManager.recipe_level(id)
  var row: HBoxContainer=HBoxContainer.new()
  row.custom_minimum_size=Vector2(640,34)
  row.add_theme_constant_override("separation",6)
  upgrade_rows.add_child(row)
  var label: Label=UIStyle.label("%s  Lv %s" % [info.name,lvl],24)
  label.custom_minimum_size.x=230
  label.tooltip_text=info.shape
  label.mouse_filter=Control.MOUSE_FILTER_STOP
  row.add_child(label)
  var value: Label=UIStyle.label("%sx%s > %sx%s" % [RecipeCatalog.candys(id,lvl),RecipeCatalog.mult(id,lvl),RecipeCatalog.candys(id,lvl+1),RecipeCatalog.mult(id,lvl+1)],24,UIStyle.MINT)
  value.custom_minimum_size.x=240
  row.add_child(value)
  var source: Label=UIStyle.label("From packs",20,UIStyle.MUTED)
  source.custom_minimum_size.x=140
  source.tooltip_text="%s\nNext level: +%s Candys, +%s Mult. Find Recipe Packs in the shop." % [info.shape,info.level_candys,info.level_mult]
  source.mouse_filter=Control.MOUSE_FILTER_STOP
  row.add_child(source)
  recipe_rows[id]=row
 var candy_heading: Label=UIStyle.label("CANDY VALUES  (Candys each: now > next)",24,UIStyle.MINT)
 upgrade_rows.add_child(candy_heading)
 for color: int in range(GameManager.config.candies.size()):
  var candy: CandyData=GameManager.config.candies[color]
  var row: HBoxContainer=HBoxContainer.new()
  row.custom_minimum_size=Vector2(640,34)
  row.add_theme_constant_override("separation",6)
  upgrade_rows.add_child(row)
  var icon: TextureRect=TextureRect.new()
  icon.texture=candy.texture
  icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.custom_minimum_size=Vector2(32,32)
  row.add_child(icon)
  var label: Label=UIStyle.label("%s  Lv %s" % [candy.display_name,GameManager.candy_level(color)],24)
  label.custom_minimum_size.x=262
  label.tooltip_text="Level %s | +%s Candys from upgrades" % [GameManager.candy_level(color),GameManager.candy_bonus(color)]
  label.mouse_filter=Control.MOUSE_FILTER_STOP
  row.add_child(label)
  var value: Label=UIStyle.label("%s > %s" % [GameManager.candy_value(color),GameManager.candy_value(color)+GameManager.upgrade_gain(color)],24,UIStyle.MINT)
  value.custom_minimum_size.x=136
  row.add_child(value)
  var source: Label=UIStyle.label("From packs",20,UIStyle.MUTED)
  source.custom_minimum_size.x=140
  source.tooltip_text="Next level: +%s Candys each. Find Candy Packs in the shop." % GameManager.upgrade_gain(color)
  source.mouse_filter=Control.MOUSE_FILTER_STOP
  row.add_child(source)
  candy_rows.append(row)

# --- Joker details ---
func reason(item: JokerData) -> String:
 if GameManager.jokers.has(item.id): return "Already owned"
 if GameManager.jokers.equipped.size() >= GameManager.jokers.capacity: return "No Joker slots left. Select an owned card above to sell it."
 if GameManager.gummies < GameManager.offer_price(item): return "Need %s more" % UIStyle.money(GameManager.offer_price(item)-GameManager.gummies)
 return ("FREE  |  " if GameManager.offer_price(item)==0 else "")+"After: %s" % UIStyle.money(GameManager.gummies-GameManager.offer_price(item))
func inspect(item: JokerData, owned: bool = false) -> void:
 close_levels()
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
 $Receipt.text = "New Jokers: -%s" % UIStyle.money(cost)

# --- The shop row ---
func refresh() -> void:
 if GameManager.state != "shop": return
 # After a skip the shop is closed until the next cleared round.
 var closed: bool = GameManager.shop_closed
 for control: Control in [shaker_buy,levels_button,joker_heading,pack_heading]: control.visible = not closed
 if closed: close_levels()
 shaker_buy.text="Items  %s / 2" % GameManager.consumables.size()
 shaker_buy.disabled=false
 shaker_buy.tooltip_text="Two random cards per shop refresh. Each offer can be bought once; hold up to two."
 $Actions/Continue.text = "Next:\n"+("Boss" if (GameManager.round_index+1)%3==2 else ("Small" if (GameManager.round_index+1)%3==0 else "Big"))
 $Heading.text = "SKIPPED" if GameManager.shop_closed else "SHOP"
 $Wallet.text = "Available cash: %s" % UIStyle.money(GameManager.gummies)
 if GameManager.last_summary.begins_with("Skipped"): $Receipt.text = GameManager.last_summary
 else: $Receipt.text = "Round reward +%s" % UIStyle.money(GameManager.last_award)+("  (interest %s)" % UIStyle.money(GameManager.last_interest) if GameManager.last_interest>0 else "")
 $Receipt.tooltip_text = GameManager.last_summary
 $Actions/Reroll.visible = not closed
 $Actions/Reroll.text = "Reroll\n"+("Free x%s" % GameManager.free_rerolls if GameManager.free_rerolls > 0 else UIStyle.money(GameManager.reroll_cost))
 $Actions/Reroll.disabled = GameManager.gummies < GameManager.current_reroll_cost()
 $Actions/Reroll.tooltip_text = "New Jokers (packs stay). Costs %s." % UIStyle.money(GameManager.current_reroll_cost())
 for child: Node in $Offers.get_children():
  $Offers.remove_child(child)
  child.queue_free()
 offer_buttons.clear()
 card_buttons.clear()
 pack_buttons.clear()
 pack_cards.clear()
 for slot: int in range(JOKER_SLOTS): add_joker_column(slot)
 for slot: int in range(2): add_pack_column(slot)
 if selected != null and selected not in GameManager.offers and selected not in GameManager.jokers.equipped: selected = null
 update_details()
 if levels_open: refresh_levels()
 if GameManager.shop_closed:
  $Details.show()
  $Details/Name.text = "Shop skipped"
  describe("Skipped for a Tag: no shop this time.")
  $Details/Status.text = ""
  $Details/Action.hide()

func empty_column(column: VBoxContainer, text: String) -> void:
 var label: Label = UIStyle.label(text,32,UIStyle.MUTED)
 label.custom_minimum_size = Vector2(140,242)
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 column.add_child(label)

func new_column() -> VBoxContainer:
 var column: VBoxContainer = VBoxContainer.new()
 column.custom_minimum_size = Vector2(140,244)
 column.add_theme_constant_override("separation",12)
 $Offers.add_child(column)
 return column

func add_joker_column(slot: int) -> void:
 var column: VBoxContainer = new_column()
 if slot >= GameManager.offers.size():
  empty_column(column,"CLOSED" if GameManager.shop_closed else "SOLD")
  return
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

func add_pack_column(slot: int) -> void:
 var column: VBoxContainer = new_column()
 if GameManager.shop_closed:
  empty_column(column,"CLOSED")
  return
 if slot >= GameManager.pack_offers.size():
  empty_column(column,"OPENED")
  return
 var pack: Dictionary = GameManager.pack_offers[slot]
 var art: TextureRect = TextureRect.new()
 art.texture = UIStyle.texture(PackCatalog.ITEMS[pack.kind].art)
 art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 art.custom_minimum_size = Vector2(140,188)
 art.tooltip_text = "%s\n%s\nShows %s cards, keep %s." % [PackCatalog.kind_name(pack),PackCatalog.ITEMS[pack.kind].blurb,PackCatalog.size(pack),PackCatalog.picks(pack)]
 art.mouse_filter = Control.MOUSE_FILTER_STOP
 CardTilt.attach(art)
 if pack.jumbo:
  var jumbo: TextureRect = TextureRect.new()
  jumbo.texture = UIStyle.texture("pack_jumbo")
  jumbo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  jumbo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  jumbo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  jumbo.mouse_filter = Control.MOUSE_FILTER_IGNORE
  art.add_child(jumbo)
 column.add_child(art)
 pack_cards.append(art)
 var price: int = PackCatalog.price(pack)
 var open: Button = Button.new()
 open.text = "Open FREE" if price==0 else "Open %s" % UIStyle.money(price)
 open.custom_minimum_size = Vector2(140,42)
 open.add_theme_font_size_override("font_size",24)
 open.disabled = not GameManager.can_open_pack(slot)
 UIStyle.role(open,"buy")
 open.tooltip_text = PackCatalog.kind_name(pack)+("" if not open.disabled else "\nNeed %s more cash." % UIStyle.money(price-GameManager.gummies))
 open.pressed.connect(func() -> void: GameManager.open_pack(slot))
 column.add_child(open)
 pack_buttons.append(open)

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
