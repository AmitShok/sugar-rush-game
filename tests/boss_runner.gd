extends "res://tests/upgrade_runner.gd"
# Boss pool, per-run draws, boss rules, chocolate/frosting/jelly obstacles, HUD/route display and saves.
var cfg: RunConfig = preload("res://resources/default_run.tres")
var rules: JokerManager
var model: BoardModel
func fresh() -> void:
 # Pattern with no matches: rows step by 1, columns by 2 (mod 6).
 model.cells.clear()
 model.isotopes.clear()
 model.graves.clear()
 model.jelly.clear()
 model.locked_color = -1
 model.sour_color = -1
 model.boss = "none"
 model.chocolate_broken = 0
 for i: int in range(64): model.cells.append(CandyState.new((i%8+2*(i/8))%6))
func line(ids: Array, color: int = 0) -> Dictionary:
 var cells: Array[int] = []
 for i: int in ids:
  cells.append(i)
  model.cells[i].color = color
 return {"cells":cells,"color":color,"length":cells.size(),"diagonal":false,"shape":false,"axis":Vector2i.RIGHT}
func force_boss(kind: String) -> void:
 GameManager.boss_cache.assign([kind,kind,kind,kind,kind,kind])
 GameManager.boss_cache_seed = GameManager.run_seed
func run_tests() -> void:
 # Boss pool and draws.
 check(BossCatalog.ORDER.size()==9,"Nine bosses in the pool")
 var seen: Dictionary={}
 var deterministic: bool=true
 var distinct: bool=true
 for s: int in range(60):
  var draw: Array[String]=BossCatalog.for_run(s)
  deterministic=deterministic and draw==BossCatalog.for_run(s)
  var unique: Dictionary={}
  for id: String in draw:
   unique[id]=true
   seen[id]=true
  distinct=distinct and unique.size()==6
 check(deterministic and distinct,"Each run draws six different bosses, reproducibly from the seed")
 check(seen.size()==9,"Every boss appears across runs")
 rules=JokerManager.new()
 model=BoardModel.new()
 model.setup(cfg,rules,31)
 model.candy_bonuses.resize(6)
 model.candy_bonuses.fill(0)
 # Chocolate.
 fresh()
 model.setup_boss("chocolatier")
 check(model.cells[17].chocolate and model.cells[46].chocolate and not model.playable(17) and not model.matchable(17),"Chocolatier places chocolate that cannot be swapped or matched")
 var spread: int=model.spread_chocolate()
 check(spread>=0 and model.cells[spread].chocolate,"Chocolate spreads when a move broke none")
 fresh()
 model.setup_boss("chocolatier")
 var e: Dictionary=model.expand(line([9,10,11],0))
 check(17 in e.cells and model.chocolate_broken==1 and 17 in e.broken,"A match beside chocolate breaks it")
 check(model.spread_chocolate()==-1,"No spread after breaking chocolate")
 check(int(e.contributions[17])==10,"Broken chocolate pays the breaking bonus")
 model.remove(e.cells)
 model.refill()
 check(model.cells[46].chocolate and model.xy(46)==Vector2i(6,5),"Chocolate anchors gravity")
 # Frosting.
 fresh()
 model.setup_boss("frost")
 check(model.cells[27].frosting==2 and not model.matchable(27),"Frost places two-layer frosting")
 e=model.expand(line([18,19,20],0))
 check(model.cells[27].frosting==1 and 27 not in e.cells and 27 in e.broken,"First hit removes one layer and the frosting stays")
 e=model.expand(line([18,19,20],0))
 check(27 in e.cells,"Second hit clears the frosting")
 # Sour, Spoon, Jelly.
 fresh()
 model.boss="sour"
 model.sour_color=0
 e=model.expand(line([0,1,2],0))
 check(int(e.chips)==0,"Sour candies score 0 Candys")
 fresh()
 model.boss="spoon"
 var g: Dictionary=line([0,1,2],0)
 e=model.expand(g)
 check(ScoreEngine.calculate(e.chips,g,false,rules,0,false,false,64,0).total==roundi(30*0.5),"Tiny Spoon halves Mult")
 fresh()
 model.setup_boss("jelly")
 check(model.jelly==BossCatalog.jelly_cells(8,8,model.jelly_count) and not model.jelly.is_empty(),"Jelly Mould lays out its jelly pattern")
 var jelly_start: int=-1
 for i: int in model.jelly:
  if model.xy(i).x <= 5:
   jelly_start=i
   break
 g=line([jelly_start,jelly_start+1,jelly_start+2],0)
 e=model.expand(g)
 check(g.curse_mult==1.0 and jelly_start not in model.jelly,"A match on jelly clears it")
 g=line([jelly_start,jelly_start+1,jelly_start+2],0)
 e=model.expand(g)
 check(g.curse_mult==1.0,"Matches off the jelly keep full score (no more half-score rule)")
 # Live game: rules tied to GameManager.
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 GameManager.start_run(9100)
 GameManager.motion=false
 var board: GameBoard=main.board
 GameManager.round_index=2
 force_boss("hurry")
 GameManager.start_round()
 check(GameManager.curse()=="hurry" and GameManager.moves==cfg.rounds[2].moves-3,"Rush Hour removes 3 moves")
 check(GameManager.round_name(2)=="The Rush Hour" and main.get_node("Play/UI_Hud/Layout/Blind").text=="The Rush Hour","HUD names the boss")
 force_boss("tax")
 GameManager.start_round()
 GameManager.gummies=2
 GameManager.begin_move(true)
 GameManager.begin_move(true)
 GameManager.begin_move(true)
 check(GameManager.gummies==0,"Sugar Tax charges $1 per move and never goes below $0")
 for kind: String in BossCatalog.ORDER:
  force_boss(kind)
  GameManager.start_round()
  await frames()
  var hud_text: String=main.get_node("Play/UI_Hud/Layout/Curse").text
  check(not hud_text.is_empty() and main.get_node("Play/UI_Hud").get_global_rect().end.y<=710,"HUD explains %s and fits" % kind)
  check(UIStyle.texture("ui_"+kind)!=null,"Route icon exists for "+kind)
  check(board.model.legal_moves().size()>0,"Boss board starts playable: "+kind)
  if kind in ["chocolatier","frost","jelly","sour"]: await capture("boss_"+kind)
 # The Jelly Mould is only beaten once every jelly tile is gone, whatever the score.
 force_boss("jelly")
 GameManager.start_round()
 await frames()
 check(GameManager.jelly_left==board.model.jelly.size() and GameManager.jelly_left > 0,"The board reports how much jelly is left")
 check(main.get_node("Play/UI_Hud/Layout/Curse").text.contains("JELLY LEFT: %s" % GameManager.jelly_left),"HUD counts the jelly left")
 GameManager.score=GameManager.current_round().quota*3
 GameManager.moves=5
 GameManager.finish_move()
 check(GameManager.state=="playing","Reaching the score with jelly left does not end the round")
 board.model.jelly.clear()
 board.sync_tiles(false)
 GameManager.finish_move()
 check(GameManager.state=="shop","Clearing the last jelly with the score met wins the round")
 GameManager.round_index=2
 force_boss("jelly")
 GameManager.start_round()
 await frames()
 GameManager.score=GameManager.current_round().quota*3
 GameManager.moves=0
 GameManager.finish_move()
 check(GameManager.state=="over","Running out of moves with jelly left loses, even over the score")
 main.get_node("GameOverScreen").visible=false
 GameManager.start_run(9100)
 GameManager.round_index=2
 # Route preview shows the drawn bosses.
 GameManager.boss_cache.clear()
 var drawn: Array[String]=BossCatalog.for_run(GameManager.run_seed)
 main.route.preview_seed=-1
 main.route.show_round(2)
 check(main.route.subtitle.text.contains(BossCatalog.ITEMS[drawn[0]].short),"Route preview names this run's ante-1 boss")
 main.route.visible=false
 # Saves.
 GameManager.round_index=2
 force_boss("frost")
 GameManager.start_round()
 board.model.cells[27].frosting=1
 board.model.cells[0].chocolate=true
 board.model.jelly.assign([5,6])
 board.model.sour_color=3
 main.run_save.checkpoint()
 board.model.cells[27].frosting=0
 board.model.cells[0].chocolate=false
 board.model.jelly.clear()
 board.model.sour_color=-1
 check(main.run_save.restore() and board.model.cells[27].frosting==1 and board.model.cells[0].chocolate and board.model.jelly==[5,6] and board.model.sour_color==3,"Obstacles, jelly and sour type survive save and Continue")
 var old: Array[CandyState]=main.run_save.unpack_cells([[1,0,0,0,0]])
 check(not old[0].chocolate and old[0].frosting==0,"Older five-field saves load without obstacles")
 print("RESULT: %s boss/obstacle checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
