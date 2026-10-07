extends PanelContainer
signal inspect_requested(item: JokerData)
func _ready() -> void:
 GameManager.changed.connect(refresh)
 refresh()
func refresh() -> void:
 $Layout/Title.text = "%s  %s / %s%s" % ["Owned Jokers" if GameManager.state=="shop" else "Jokers",GameManager.jokers.equipped.size(),GameManager.jokers.capacity,""]
 for child: Node in $Layout/Slots.get_children():
  $Layout/Slots.remove_child(child)
  child.queue_free()
 for i: int in range(GameManager.jokers.capacity):
  var slot: Control = Control.new()
  slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  slot.custom_minimum_size = Vector2(124,104)
  $Layout/Slots.add_child(slot)
  if i >= GameManager.jokers.equipped.size():
   var empty: Label = UIStyle.label("Empty",24,Color("98b2a8"))
   empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
   empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
   slot.add_child(empty)
   continue
  var item: JokerData = GameManager.jokers.equipped[i]
  var card: JokerCardButton = JokerCardButton.new()
  card.item = item
  card.texture_normal = item.icon
  card.ignore_texture_size = true
  card.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
  card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  card.tooltip_text = item.display_name+"\n"+item.description
  card.pressed.connect(func() -> void: inspect_requested.emit(item))
  card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  slot.add_child(card)
 $Layout/Streak.text = "Streak %s" % GameManager.streak
