class_name JokerCardButton
extends TextureButton
var item: JokerData
func _make_custom_tooltip(_text: String) -> Object:
 if item == null: return null
 var panel: PanelContainer = PanelContainer.new()
 panel.add_theme_stylebox_override("panel",UIStyle.box(Color("172c32"),Color("f4c76b"),2))
 var column: VBoxContainer = VBoxContainer.new()
 panel.add_child(column)
 var title: Label = UIStyle.label(item.display_name,32,Color("ffd57b"))
 title.custom_minimum_size.x = 320
 title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 column.add_child(title)
 var description: Label = UIStyle.label(GameManager.joker_description(item),24)
 description.custom_minimum_size.x = 320
 description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 column.add_child(description)
 return panel
