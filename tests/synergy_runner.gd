extends Node
var checks: int = 0
var failures: int = 0
var cfg: RunConfig = preload("res://resources/default_run.tres")
func check(ok: bool, message: String) -> void:
 checks += 1
 if ok: print("PASS: "+message)
 else:
  failures += 1
  push_error("FAIL: "+message)
func _ready() -> void:
 call_deferred("run_tests")
func item(id: String) -> JokerData:
 for card: JokerData in cfg.jokers:
  if card.id == id: return card
 return null
func fixture(rules: JokerManager) -> BoardModel:
 var model: BoardModel = BoardModel.new()
 model.setup(cfg,rules,55)
 for i: int in range(64): model.cells.append(CandyState.new((i%8+i/8*2)%6))
 for i: int in [25,26,27,28,29]: model.cells[i].color = 0
 model.cells[60].blocker = 3
 model.graves.append(61)
 return model
func group(length: int) -> Dictionary:
 var ids: Array[int] = [25,26,27,28]
 if length == 5: ids.append(29)
 return {"cells":ids,"color":0,"length":length,"axis":Vector2i.RIGHT,"shape":false,"diagonal":false}
func run_tests() -> void:
 var rules: JokerManager = JokerManager.new()
 add_child(rules)
 var pairs_ok: bool = true
 for a: JokerData in cfg.jokers:
  for b: JokerData in cfg.jokers:
   if a == b: continue
   rules.equipped.clear()
   pairs_ok = rules.add(a) and rules.add(b) and pairs_ok
 check(pairs_ok,"All 231 distinct Joker pairs can be equipped in either order")
 rules.equipped.clear()
 for id: String in ["paintball","gravity","sledgehammer","ricochet","labyrinth"]: rules.add(item(id))
 check(rules.equipped.size()==5 and not rules.add(item("midas")),"A full four-match build fits five slots; capacity still applies")
 var model: BoardModel = fixture(rules)
 var result: Dictionary = model.expand(group(4))
 check(result.effects.size()==4 and 60 in result.cells and not model.recycled.is_empty(),"All four 4+ effects trigger together, including hammer and caramel refill")
 check(model.cells[17].color==0 and 17 in result.cells,"Repainting feeds same-color Gravity attraction in the same match")
 var unique: Dictionary = {}
 var chips: int = 0
 for i: int in result.cells:
  unique[i] = true
  chips += int(result.contributions[i])
 check(unique.size()==result.cells.size() and chips==result.chips,"Overlapping synergy clears contain no duplicate candy or chips")
 rules.equipped.reverse()
 var reverse_model: BoardModel = fixture(rules)
 var reverse_result: Dictionary = reverse_model.expand(group(4))
 check(result==reverse_result,"Purchase order does not change stacked effect results")
 rules.equipped.clear()
 for id: String in ["nuclear","midas","prism","necro","gravity"]: rules.add(item(id))
 model=fixture(rules)
 result=model.expand(group(5))
 check(result.effects.size()==5 and result.wild==25 and 25 in model.isotopes,"Four 5+ effects and a 4+ effect combine on one five-match")
 check(model.cells[60].blocker==0 and model.cells[60].coating==2 and model.cells[25].coating==2,"Revival and gilding both apply before stacked scoring")
 check(not result.isotope,"A new isotope does not multiply its own creation match")
 result=model.expand(group(5))
 check(result.isotope,"A later clear uses the persistent isotope multiplier")
 # Compare huge and exact quota scores using the same move count.
 GameManager.start_run(123)
 GameManager.moves=6
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 var payout: int=GameManager.last_award
 GameManager.start_run(123)
 GameManager.moves=6
 GameManager.score=1000000
 GameManager.settle_round()
 check(payout==7 and GameManager.last_award==payout and GameManager.gummies==11,"One million score pays the same $7 as exact quota with six moves left")
 var bounded: bool=true
 var total: int=0
 for round_id: int in range(9):
  GameManager.round_index=round_id
  GameManager.moves=100
  GameManager.score=1000000
  GameManager.settle_round()
  bounded = bounded and GameManager.last_award==[8,10,13][round_id%3]
  total += GameManager.last_award
 check(bounded and total==93,"Nine-round cash is bounded at $93 plus $4 starting cash")
 var main: Control=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await get_tree().process_frame
 main.start()
 GameManager.motion=true
 var board: GameBoard=main.get_node("Play/GameBoard")
 var legal: Array[Vector2i]=board.model.legal_moves()
 board.choose(legal[0].x)
 board.choose(legal[0].y)
 main.toggle_pause()
 var before: int=GameManager.moves
 var position_before: Vector2=board.tiles[legal[0].x].position
 await get_tree().create_timer(0.3,true).timeout
 check(get_tree().paused and board.busy and GameManager.moves==before and board.tiles[legal[0].x].position==position_before,"Pausing mid-swap freezes animation and move resolution")
 main.get_node("Pause/Layout/Options").pressed.emit()
 check(main.get_node("Pause/Layout/Sound").visible and main.get_node("Pause/Layout/Back").visible,"Options opens sound and motion controls")
 main.get_node("Pause/Layout/Back").pressed.emit()
 check(main.get_node("Pause/Layout/Quit").visible and main.get_node("Pause/Layout/Abandon").visible,"Pause offers both Quit to Title and Quit to Desktop")
 await capture("v4_pause")
 main.get_node("Pause/Layout/Resume").pressed.emit()
 while board.busy: await get_tree().process_frame
 check(not get_tree().paused and not board.paused and GameManager.moves==before-1,"Resume finishes the frozen move exactly once")
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 main.get_node("Shop/PauseButton").pressed.emit()
 check(get_tree().paused and main.get_node("Pause").visible,"Shop has a working pause button")
 main.get_node("Pause/Layout/Abandon").pressed.emit()
 check(not get_tree().paused and GameManager.state=="menu" and main.get_node("Menu").visible,"Quit to Title unpauses and ends the run")
 # Real scene resolver with each stacked build, including cascades.
 for build: Array in [["paintball","gravity","sledgehammer","ricochet","labyrinth"],["nuclear","midas","prism","necro","gravity"]]:
  main.start()
  GameManager.motion=false
  for id: String in build: GameManager.jokers.add(item(id))
  board.model=fixture(GameManager.jokers)
  board.sync_tiles(false)
  var groups: Array[Dictionary]=[group(4 if build[0]=="paintball" else 5)]
  await board.resolve(groups)
  check(null not in board.model.cells and board.model.matches().is_empty() and GameManager.score>0,"Stacked build resolves and refills through the live board: "+str(build))
 print("RESULT: %s synergy/economy/pause checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 var folder: String=OS.get_environment("SUGAR_CAPTURE_DIR")
 if not folder.is_empty(): get_viewport().get_texture().get_image().save_png(folder+"/"+name+".png")
