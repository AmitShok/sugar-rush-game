extends Control
# Modal shown while a booster pack is open: pick cards from GameManager.opened_pack, or skip the rest.
var heading: Label
var summary: Label
var cards: HBoxContainer
var skip_button: Button
var take_buttons: Array[Button] = []
func _ready() -> void:
 z_index=195
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
 heading=UIStyle.label("",44)
 heading.position=Vector2(64,48)
 add_child(heading)
 summary=UIStyle.label("",24)
 summary.position=Vector2(64,104)
 add_child(summary)
 cards=HBoxContainer.new()
 cards.position=Vector2(64,150)
 cards.add_theme_constant_override("separation",14)
 cards.size=Vector2(1024,440)
 cards.alignment=BoxContainer.ALIGNMENT_CENTER
 add_child(cards)
 skip_button=Button.new()
 skip_button.name="Skip"
 skip_button.position=Vector2(812,624)
 skip_button.size=Vector2(276,44)
 skip_button.add_theme_font_size_override("font_size",24)
 skip_button.pressed.connect(GameManager.skip_pack)
 UIStyle.role(skip_button,"neutral")
 add_child(skip_button)
 GameManager.changed.connect(refresh)
 hide()
func refresh() -> void:
 visible = not GameManager.opened_pack.is_empty()
 if not visible: return
 var pack: Dictionary = GameManager.opened_pack
 heading.text = PackCatalog.kind_name(pack).to_upper()
 var picks: int = int(pack.picks)
 summary.text = "Keep %s more %s. Cash: %s" % [picks,"card" if picks == 1 else "cards",UIStyle.money(GameManager.gummies)]
 skip_button.text = "Skip the rest" if picks < PackCatalog.picks(pack) else "Skip pack"
 for child: Node in cards.get_children():
  cards.remove_child(child)
  child.queue_free()
 take_buttons.clear()
 var width: float = 190.0 if pack.choices.size() > 4 else 238.0
 for i: int in range(pack.choices.size()):
  var choice: Dictionary = pack.choices[i]
  var column: VBoxContainer = VBoxContainer.new()
  column.custom_minimum_size = Vector2(width,440)
  column.add_theme_constant_override("separation",8)
  cards.add_child(column)
  var info: Dictionary = describe(choice)
  var title: Label = UIStyle.label(info.title,22,UIStyle.MINT)
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  title.custom_minimum_size = Vector2(width,56)
  column.add_child(title)
  var art: TextureRect = TextureRect.new()
  art.texture = info.art
  art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  art.custom_minimum_size = Vector2(width,150)
  art.mouse_filter = Control.MOUSE_FILTER_PASS
  CardTilt.attach(art)
  column.add_child(art)
  if choice.type == "joker": UIStyle.add_edition_overlay(art,String(choice.get("edition","")))
  var text: Label = UIStyle.label(info.text,20)
  text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  text.custom_minimum_size = Vector2(width,150)
  column.add_child(text)
  var take: Button = Button.new()
  var blocked: String = GameManager.pack_block_reason(choice)
  take.text = "Take" if blocked.is_empty() else "Full"
  take.disabled = not blocked.is_empty()
  take.tooltip_text = blocked
  take.custom_minimum_size = Vector2(width,42)
  take.add_theme_font_size_override("font_size",24)
  UIStyle.role(take,"go")
  take.pressed.connect(GameManager.take_pack_card.bind(i))
  column.add_child(take)
  take_buttons.append(take)
func describe(choice: Dictionary) -> Dictionary:
 var gm: Node = GameManager
 match String(choice.type):
  "joker":
   var item: JokerData = gm.joker_by_id(String(choice.id))
   var edition: String = String(choice.get("edition",""))
   var title: String = item.display_name+(" (%s)" % EditionCatalog.ITEMS[edition].name if not edition.is_empty() else "")
   var extra: String = "\n"+EditionCatalog.label(edition) if not edition.is_empty() else ""
   return {"title":title,"art":item.icon,"text":item.description+extra}
  "recipe":
   var id: String = String(choice.id)
   var lvl: int = gm.recipe_level(id)
   return {"title":"%s  Lv %s > %s" % [RecipeCatalog.ITEMS[id].name,lvl,lvl+1],"art":UIStyle.texture("pack_recipe"),"text":"%s\n%sx%s > %sx%s" % [RecipeCatalog.ITEMS[id].shape,RecipeCatalog.candys(id,lvl),RecipeCatalog.mult(id,lvl),RecipeCatalog.candys(id,lvl+1),RecipeCatalog.mult(id,lvl+1)]}
  "candy":
   var color: int = int(choice.id)
   var candy: CandyData = gm.config.candies[color]
   return {"title":candy.display_name,"art":candy.texture,"text":"+%s Candys each\n%s > %s Candys" % [gm.upgrade_gain(color),gm.candy_value(color),gm.candy_value(color)+gm.upgrade_gain(color)]}
  "treat":
   var item: Dictionary = ConsumableCatalog.ITEMS[String(choice.id)]
   return {"title":item.name,"art":UIStyle.texture(item.art),"text":item.description}
 var rush: Dictionary = PackCatalog.RUSH[String(choice.id)]
 return {"title":rush.name,"art":UIStyle.texture("pack_rush"),"text":rush.description}
