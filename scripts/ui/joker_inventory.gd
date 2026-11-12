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
  # Slots share the bar: five at 124 px, six (Big Spoon) narrower so the bar never overflows.
  slot.custom_minimum_size = Vector2(slot_width(),104)
  $Layout/Slots.add_child(slot)
  if i >= GameManager.jokers.equipped.size():
   var empty: Label = UIStyle.label("Empty",24,Color("a48fb0"))
   empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
   empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
   slot.add_child(empty)
   continue
  var item: JokerData = GameManager.jokers.equipped[i]
  var card: JokerCardButton = JokerCardButton.new()
  card.item = item
  card.texture_normal = item.icon
  CardTilt.attach(card)
  UIStyle.add_edition_overlay(card,GameManager.jokers.edition(item.id))
  card.ignore_texture_size = true
  card.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
  card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  card.tooltip_text = GameManager.joker_title(item)+"\n"+GameManager.joker_text(item)
  card.pressed.connect(func() -> void: inspect_requested.emit(item))
  card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  slot.add_child(card)
 $Layout/Streak.text = "Streak %s" % GameManager.streak
# Inner width of the 760 px bar minus panel padding, split across all slots and gaps.
const INNER_WIDTH: float = 732.0
func slot_width() -> float:
 var count: int = maxi(1,GameManager.jokers.capacity)
 var gap: float = float($Layout/Slots.get_theme_constant("separation"))
 return minf(124.0,floorf((INNER_WIDTH-gap*(count-1))/count))
