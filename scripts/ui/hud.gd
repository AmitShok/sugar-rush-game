extends PanelContainer
var score_tween: Tween
var shown_score: int = 0
var target_score: int = -1
func _ready() -> void:
 $Layout/Goal.add_theme_stylebox_override("panel",UIStyle.box(Color("182e34"),Color("233b43"),2))
 $Layout/Math/Chips.add_theme_stylebox_override("normal",UIStyle.box(Color("168dcc"),Color("49b4dd")))
 $Layout/Math/Mult.add_theme_stylebox_override("normal",UIStyle.box(Color("ce4546"),Color("ee7064")))
 GameManager.changed.connect(refresh)
 refresh()
func refresh() -> void:
 var gm: Node = GameManager
 var shopping: bool = gm.state == "shop"
 for key: String in ["Goal","ScoreLabel","Score","Progress","Math","Equation","Moves","Curse"]:
  $Layout.get_node(key).visible = not shopping
 size.y = 360 if shopping else 664
 $Layout/Ante.text = "ANTE %02d   /   %02d" % [gm.round_index/3+1,gm.config.rounds.size()/3]
 $Layout/Blind.text = gm.current_round().display_name
 if gm.current_round().curse == "inspector": $Layout/Blind.text = "The Inspector"
 if shopping: $Layout/Blind.text = "SHOP"
 $Layout/Goal/Column/Quota.text = "%s" % gm.current_round().quota
 if target_score != gm.score:
  target_score = gm.score
  if score_tween: score_tween.kill()
  if GameManager.motion and gm.score > shown_score:
   score_tween = create_tween()
   score_tween.tween_method(display_score,float(shown_score),float(gm.score),0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  else: display_score(float(gm.score))
 $Layout/Progress.max_value = gm.current_round().quota
 $Layout/Progress.value = gm.score
 $Layout/Math/Chips.text = str(int(gm.last_chips)) if is_equal_approx(gm.last_chips,roundf(gm.last_chips)) else str(snappedf(gm.last_chips,0.1))
 $Layout/Math/Mult.text = str(int(gm.last_mult)) if is_equal_approx(gm.last_mult,roundf(gm.last_mult)) else str(snappedf(gm.last_mult,0.1))
 $Layout/Moves.text = "%02d   MOVES LEFT" % gm.moves
 $Layout/Wallet.text = UIStyle.money(gm.gummies)
 $Layout/Route.hide()
 $Layout/Curse.text = gm.current_round().description
 if gm.current_round().curse=="inspector":
  var board: GameBoard=get_parent().get_node("GameBoard") as GameBoard
  if board.model.locked_color>=0: $Layout/Curse.text="LOCKED: "+gm.config.candies[board.model.locked_color].display_name+"\nMatch 3 including it to break."
 $Layout/Curse.add_theme_font_size_override("font_size",20 if gm.poison >= 0 else 24)
 if gm.poison >= 0:
  var rule: String=""
  if gm.current_round().curse=="inspector":
   var board: GameBoard=get_parent().get_node("GameBoard") as GameBoard
   if board.model.locked_color>=0: rule="Locked: "+gm.config.candies[board.model.locked_color].display_name+"\n"
  elif gm.current_round().curse=="heatwave": rule="Heatwave: 4 idle moves lock.\n"
  $Layout/Curse.text=rule+"Roulette: "+gm.config.candies[gm.poison].display_name+"\n"+("Matched" if gm.poison_cleared else "Match needed")+" | x2 Mult"

func display_score(value: float) -> void:
 shown_score = roundi(value)
 $Layout/Score.text = str(shown_score)
func _process(_delta: float) -> void:
 # Container minimum sizes update after fonts and visibility change.
 # Reapply the intended height once that layout pass has completed.
 var height: float = 360.0 if GameManager.state == "shop" else 664.0
 if not is_equal_approx(size.y,height): size.y = height
