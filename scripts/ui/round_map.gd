extends Control
signal entered
signal returned
var target_index: int = 0
var cards: Array[Panel] = []
var heading: Label
var subtitle: Label
var row: Control
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
 # Fixed logical rectangles avoid deferred nested-container layout when this
 # hidden modal is first opened on mobile. Draw content above its own shade.
 var panel: Panel = Panel.new()
 panel.name="Content"
 panel.z_index=1
 panel.position=Vector2(146,48)
 panel.size=Vector2(860,648)
 panel.add_theme_stylebox_override("panel",UIStyle.skin("ui_panel"))
 add_child(panel)
 heading=UIStyle.label("THE ROAD AHEAD",40)
 place(panel,heading,Rect2(16,12,828,52))
 subtitle=UIStyle.label("",24)
 place(panel,subtitle,Rect2(16,68,828,36))
 row=Control.new()
 place(panel,row,Rect2(16,112,828,380))
 var help: Label=UIStyle.label("Win the Small and Big batches to reach the Boss.\nShop between rounds. Defeat %s bosses to win the run." % (GameManager.config.rounds.size()/3),24)
 place(panel,help,Rect2(16,504,828,64))
 back_button=Button.new()
 back_button.text="Back"
 back_button.pressed.connect(func() -> void: returned.emit())
 place(panel,back_button,Rect2(16,588,180,48))
 enter_button=Button.new()
 UIStyle.button_color(enter_button,Color("388e63"))
 enter_button.pressed.connect(func() -> void: entered.emit())
 place(panel,enter_button,Rect2(208,588,636,48))
 visible=false
func show_round(index: int) -> void:
 target_index=index
 visible=true
 var ante: int=index/3
 heading.text="ANTE %s / %s   |   THE ROAD AHEAD" % [ante+1,GameManager.config.rounds.size()/3]
 var gap: int=2-index%3
 subtitle.text="BOSS NEXT: %s" % boss_name(ante*3+2) if gap==0 else "%s %s to clear before %s" % [gap,"round" if gap==1 else "rounds",boss_name(ante*3+2)]
 for child: Node in row.get_children():
  row.remove_child(child)
  child.queue_free()
 cards.clear()
 for stage: int in range(3):
  var round_id: int=ante*3+stage
  var data: RoundData=GameManager.config.rounds[round_id]
  var card: Panel=Panel.new()
  card.position=Vector2(stage*280,0)
  card.size=Vector2(268,380)
  card.add_theme_stylebox_override("panel",UIStyle.skin("ui_boss" if stage==2 else "ui_panel"))
  row.add_child(card)
  cards.append(card)
  var state: Label=UIStyle.label("CLEARED" if round_id<index else ("UP NEXT" if round_id==index else "COMING UP"),24,UIStyle.MINT)
  place(card,state,Rect2(14,10,240,36))
  var icon: TextureRect=TextureRect.new()
  icon.texture=UIStyle.texture("ui_done" if round_id<index else "ui_"+(["small","big",data.curse][stage]))
  icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  place(card,icon,Rect2(14,44,240,48))
  var title: Label=UIStyle.label(["SMALL BATCH","BIG BATCH","BOSS: "+boss_name(round_id)][stage],32)
  title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  place(card,title,Rect2(14,100,240,64))
  var reward: Label=UIStyle.label("Score %s\n%s moves   |   $%s reward" % [data.quota,data.moves,[GameManager.config.clear_reward,GameManager.config.big_reward,GameManager.config.boss_reward][stage]],20)
  place(card,reward,Rect2(14,166,240,52))
  var description: Label=UIStyle.label("No special rule." if stage<2 else data.description,22)
  description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  place(card,description,Rect2(14,224,240,148))
  if round_id<index: card.modulate=Color(0.65,0.75,0.7)
 enter_button.text="Face "+boss_name(index) if index%3==2 else "Play "+GameManager.config.rounds[index].display_name
func boss_name(index: int) -> String:
 return "INSPECTOR" if GameManager.config.rounds[index].curse=="inspector" else "HEATWAVE"

func place(parent: Control,child: Control,rect: Rect2) -> void:
 parent.add_child(child)
 child.position=rect.position
 child.size=rect.size
 # Wrapped Labels first measure at their old width. Reapply the rectangle
 # after text shaping updates the minimum height for the assigned width.
 child.set_deferred("size",rect.size)
