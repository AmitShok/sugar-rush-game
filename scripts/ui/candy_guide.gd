extends Control
signal closed
var rows: VBoxContainer
var close_button: Button
func _ready() -> void:
 z_index=180
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shade: TextureRect=TextureRect.new()
 shade.texture=UIStyle.texture("ui_shade")
 shade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 var panel: PanelContainer=PanelContainer.new()
 panel.position=Vector2(166,70)
 panel.size=Vector2(820,580)
 add_child(panel)
 var column: VBoxContainer=VBoxContainer.new()
 column.add_theme_constant_override("separation",12)
 panel.add_child(column)
 column.add_child(UIStyle.label("CANDY GUIDE",48))
 var headings: HBoxContainer=HBoxContainer.new()
 column.add_child(headings)
 var candy_heading: Label=UIStyle.label("Candy / rarity",24)
 candy_heading.custom_minimum_size.x=456
 headings.add_child(candy_heading)
 var value_heading: Label=UIStyle.label("Candys",24)
 value_heading.custom_minimum_size.x=116
 headings.add_child(value_heading)
 headings.add_child(UIStyle.label("Spawn chance",24))
 rows=VBoxContainer.new()
 rows.add_theme_constant_override("separation",4)
 column.add_child(rows)
 var note: Label=UIStyle.label("Odds are per new random candy; the board is not a fixed mix.
Supply Jokers double their type's weight before normalization.

Match through a locked tile: +10 / +25 / +50 Candys
for matches of 3 / 4 / 5+, before Mult.",24)
 column.add_child(note)
 close_button=Button.new()
 close_button.text="Back"
 close_button.custom_minimum_size.y=46
 close_button.pressed.connect(func() -> void: closed.emit())
 column.add_child(close_button)
 visible=false
func show_candies() -> void:
 for child: Node in rows.get_children():
  rows.remove_child(child)
  child.queue_free()
 var model: BoardModel=BoardModel.new()
 model.setup(GameManager.config,GameManager.jokers,1)
 var chances: Array[float]=model.spawn_chances()
 for i: int in range(GameManager.config.candies.size()):
  var candy: CandyData=GameManager.config.candies[i]
  var row: HBoxContainer=HBoxContainer.new()
  row.custom_minimum_size.y=36
  rows.add_child(row)
  var icon: TextureRect=TextureRect.new()
  icon.texture=candy.texture
  icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.custom_minimum_size=Vector2(48,32)
  row.add_child(icon)
  var label: Label=UIStyle.label(candy.display_name+" / "+candy.rarity,24)
  label.custom_minimum_size.x=396
  row.add_child(label)
  var value: Label=UIStyle.label(str(candy.base_chips),32,UIStyle.MINT)
  value.custom_minimum_size.x=116
  row.add_child(value)
  row.add_child(UIStyle.label("%.1f%%" % (chances[i]*100),32))
 visible=true
