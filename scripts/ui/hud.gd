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
 $Layout/Blind.text = gm.round_name(gm.round_index)
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
 # v0.34: before a move the boxes preview its guaranteed hand (Balatro-style); during a move they
 # count the live hand up; afterwards they keep the last hand.
 var previewing: bool = not gm.preview.is_empty()
 var chips: float = float(gm.preview.get("chips",0.0)) if previewing else float(gm.last_chips)
 var mult: float = float(gm.preview.get("mult",1.0)) if previewing else float(gm.last_mult)
 $Layout/Math/Chips.text = number(chips)
 $Layout/Math/Mult.text = number(mult)
 $Layout/Equation.text = equation()
 $Layout/Equation.add_theme_color_override("font_color",UIStyle.MINT if previewing and bool(gm.preview.get("valid",false)) else (UIStyle.PINK if previewing else UIStyle.CREAM))
 $Layout/Moves.text = "%02d   %s LEFT" % [gm.moves,"MOVE" if gm.moves==1 else "MOVES"]
 $Layout/Wallet.text = UIStyle.money(gm.gummies)
 $Layout/Route.hide()
 # Normal rounds need no rule text; bosses show their short live rule (v0.29).
 var rule: String = boss_rule() if gm.curse() != "none" else ""
 $Layout/Curse.text = rule
 $Layout/Curse.add_theme_font_size_override("font_size",20 if gm.poison >= 0 else 24)
 if gm.poison >= 0:
  var short_rule: String = boss_rule()+"\n" if gm.curse() != "none" else ""
  $Layout/Curse.text=short_rule+"Roulette: "+gm.config.candies[gm.poison].display_name+"\n"+("Matched" if gm.poison_cleared else "Match needed")+" | x2 Mult"
# Short live description of this round's boss rule for the sidebar.
func boss_rule() -> String:
 var gm: Node = GameManager
 var board: GameBoard = get_parent().get_node("GameBoard") as GameBoard
 match gm.curse():
  "inspector":
   if board.model.locked_color >= 0: return "LOCKED: "+gm.config.candies[board.model.locked_color].display_name+"\nMatch 3 including it."
   return "Inspector: one type is locked."
  "heatwave": return "Heatwave: 4 idle moves lock."
  "chocolatier": return "Chocolate spreads if a\nmove breaks none."
  "frost": return "Frosting: break it with\nnearby matches."
  "sour":
   if board.model.sour_color >= 0: return "SOUR: "+gm.config.candies[board.model.sour_color].display_name+"\nscores 0 Candys."
   return "Sour Patch: one type scores 0."
  "spoon": return "Tiny Spoon: Mult halved."
  "jelly": return "JELLY LEFT: %s\nClear it all to win." % board.model.jelly.size()
  "tax": return "Sugar Tax: $1 per move."
  "hurry": return "Rush Hour: 3 fewer moves."
 return ""

func display_score(value: float) -> void:
 var previous: int = shown_score
 shown_score = roundi(value)
 # Counting ticks rise in pitch as the score climbs toward the quota.
 if shown_score != previous and shown_score < target_score:
  SoundBoard.tick(float(shown_score)/maxf(1.0,float(GameManager.current_round().quota)))
 $Layout/Score.text = str(shown_score)
func _process(_delta: float) -> void:
 # Container minimum sizes update after fonts and visibility change.
 # Reapply the intended height once that layout pass has completed.
 var height: float = 360.0 if GameManager.state == "shop" else 664.0
 if not is_equal_approx(size.y,height): size.y = height
func number(value: float) -> String:
 return str(int(value)) if is_equal_approx(value,roundf(value)) else str(snappedf(value,0.1))
# The line under Candys x Mult: the previewed hand and its guaranteed score ("+" = cascades can add),
# or the last hand's name.
func equation() -> String:
 var gm: Node = GameManager
 if not gm.preview.is_empty():
  if not bool(gm.preview.get("valid",false)): return "NO MATCH  -1 MOVE"
  var recipe: String = String(gm.preview.get("recipe",""))
  var name: String = (RecipeCatalog.ITEMS[recipe].short.to_upper()+" LV%s  " % int(gm.preview.get("level",1))) if recipe != "" else ""
  return name+"= %s+" % UIStyle.short_number(int(gm.preview.get("total",0)))
 if gm.last_recipe != "": return "%s LV%s" % [RecipeCatalog.ITEMS[gm.last_recipe].short.to_upper(),gm.recipe_level(gm.last_recipe)]
 return "CANDYS             MULT"
