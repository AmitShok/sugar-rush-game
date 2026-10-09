extends Control
signal entered
signal returned
var target_index: int = 0
var cards: Array[PanelContainer] = []
var heading: Label
var subtitle: Label
var row: HBoxContainer
var enter_button: Button
var back_button: Button
func _ready() -> void:
 z_index = 150
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shade: TextureRect = TextureRect.new()
 shade.texture = UIStyle.texture("ui_shade")
 shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 var panel: PanelContainer = PanelContainer.new()
 panel.position = Vector2(146,48)
 panel.size = Vector2(860,624)
 add_child(panel)
 var column: VBoxContainer = VBoxContainer.new()
 column.add_theme_constant_override("separation",12)
 panel.add_child(column)
 heading=UIStyle.label("THE ROAD AHEAD",48)
 column.add_child(heading)
 subtitle=UIStyle.label("",24)
 column.add_child(subtitle)
 row=HBoxContainer.new()
 row.custom_minimum_size.y=380
 column.add_child(row)
 var help: Label=UIStyle.label("Win the Small and Big batches to reach the Boss.
Shop between rounds. Defeat %s bosses to win the run." % (GameManager.config.rounds.size()/3),24)
 column.add_child(help)
 var actions: HBoxContainer=HBoxContainer.new()
 column.add_child(actions)
 back_button=Button.new()
 back_button.text="Back"
 back_button.custom_minimum_size=Vector2(180,48)
 back_button.pressed.connect(func() -> void: returned.emit())
 actions.add_child(back_button)
 enter_button=Button.new()
 enter_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 enter_button.custom_minimum_size.y=48
 UIStyle.button_color(enter_button,Color("388e63"))
 enter_button.pressed.connect(func() -> void: entered.emit())
 actions.add_child(enter_button)
 visible=false
func show_round(index: int) -> void:
 target_index=index
 visible=true
 var ante: int=index/3
 heading.text="ANTE %s / %s   |   THE ROAD AHEAD" % [ante+1,GameManager.config.rounds.size()/3]
 var gap: int=2-index%3
 subtitle.text="BOSS NEXT: %s" % boss_name(ante*3+2) if gap==0 else "%s rounds to clear before %s" % [gap,boss_name(ante*3+2)]
 for child: Node in row.get_children():
  row.remove_child(child)
  child.queue_free()
 cards.clear()
 for stage: int in range(3):
  var round_id: int=ante*3+stage
  var data: RoundData=GameManager.config.rounds[round_id]
  var card: PanelContainer=PanelContainer.new()
  card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  card.custom_minimum_size=Vector2(268,380)
  card.add_theme_stylebox_override("panel",UIStyle.skin("ui_boss" if stage==2 else "ui_panel"))
  row.add_child(card)
  cards.append(card)
  var body: VBoxContainer=VBoxContainer.new()
  body.add_theme_constant_override("separation",8)
  card.add_child(body)
  var state: Label=UIStyle.label("CLEARED" if round_id<index else ("UP NEXT" if round_id==index else "COMING UP"),24,UIStyle.MINT)
  body.add_child(state)
  var icon: TextureRect=TextureRect.new()
  icon.texture=UIStyle.texture("ui_done" if round_id<index else "ui_"+(["small","big",data.curse][stage]))
  icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.custom_minimum_size=Vector2(64,64)
  body.add_child(icon)
  var title: Label=UIStyle.label(["SMALL BATCH","BIG BATCH","BOSS: "+boss_name(round_id)][stage],32)
  title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  body.add_child(title)
  body.add_child(UIStyle.label("Score %s
%s moves   |   $%s reward" % [data.quota,data.moves,[GameManager.config.clear_reward,GameManager.config.big_reward,GameManager.config.boss_reward][stage]],24))
  var description: Label=UIStyle.label("No special rule." if stage<2 else data.description,24)
  description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  description.size_flags_vertical=Control.SIZE_EXPAND_FILL
  body.add_child(description)
  if round_id<index: card.modulate=Color(0.65,0.75,0.7)
 enter_button.text="Face "+boss_name(index) if index%3==2 else "Play "+GameManager.config.rounds[index].display_name
func boss_name(index: int) -> String:
 return "INSPECTOR" if GameManager.config.rounds[index].curse=="inspector" else "HEATWAVE"
