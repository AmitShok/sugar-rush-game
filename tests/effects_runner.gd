extends Node
var failures: int = 0
var checks: int = 0
func check(value: bool, text: String) -> void:
 checks += 1
 if value: print("PASS: "+text)
 else:
  failures += 1
  push_error("FAIL: "+text)
func _ready() -> void:
 call_deferred("run_checks")
func run_checks() -> void:
 var main: Control = preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await get_tree().process_frame
 GameManager.start_run(38038)
 GameManager.motion=false
 var board: GameBoard=main.get_node("Play/GameBoard")
 for item: JokerData in GameManager.config.jokers:
  if item.category not in ["Four","Five"]: continue
  GameManager.jokers.equipped.clear()
  GameManager.jokers.add(item)
  GameManager.start_round()
  var size: int=4 if item.category=="Four" else 5
  var ids: Array[int]=[]
  for i: int in range(size):
   board.model.cells[i].color=0
   board.model.cells[i].blocker=0
   ids.append(i)
  board.sync_tiles(false)
  var groups: Array[Dictionary]=[{"cells":ids,"color":0,"length":size,"diagonal":false,"shape":false,"axis":Vector2i.RIGHT}]
  await board.resolve(groups)
  check(board.model.cells.size()==64 and null not in board.model.cells and board.model.matches().is_empty() and GameManager.score>0,"End-to-end effect: "+item.id)
 # One wave, two separate matches sharing blast area: no duplicate chips.
 GameManager.jokers.equipped.clear()
 GameManager.start_round()
 board.model.cells.clear()
 for i: int in range(64):
  var cell: CandyState=CandyState.new(0)
  cell.blocker=2
  if i<8: cell.blocker=0
  board.model.cells.append(cell)
 board.sync_tiles(false)
 var overlap: Array[Dictionary]=[
  {"cells":[0,1,2,3],"color":0,"length":4,"diagonal":false,"shape":false,"axis":Vector2i.RIGHT},
  {"cells":[4,5,6,7],"color":0,"length":4,"diagonal":false,"shape":false,"axis":Vector2i.RIGHT}]
 var awards: Array[int]=[]
 var capture_award: Callable=func(result: Dictionary,_color: int) -> void: awards.append(result.total)
 board.matches_resolved.connect(capture_award)
 await board.resolve(overlap)
 board.matches_resolved.disconnect(capture_award)
 check(awards.size()>=2 and awards[0]==440 and awards[1]==280,"Overlapping blasts score each candy and its break bonus once")
 # Animated input paths and actual signal wiring, not only pure resolver calls.
 GameManager.start_run(42)
 GameManager.motion=true
 var legal: Array[Vector2i]=board.model.legal_moves()
 board.choose(legal[0].x)
 board.choose(legal[0].y)
 check(board.busy,"Click path locks board during tween")
 while board.busy: await get_tree().process_frame
 check(GameManager.moves==9 and GameManager.score>0,"Animated click swap completes and scores")
 main.toggle_pause()
 check(board.paused,"Pause blocks board input")
 var score_before: int=GameManager.score
 legal=board.model.legal_moves()
 await board.attempt_swap(legal[0].x,legal[0].y)
 check(GameManager.score==score_before and GameManager.moves==9,"Paused swaps do not spend moves")
 main.toggle_pause()
 main.show_codex()
 check(board.paused,"Handbook pauses keyboard and mouse board input")
 main.close_codex()
 check(not board.paused,"Closing handbook restores input")
 # A refill is movement this turn: newborn and falling tiles must not age yet.
 var probe: BoardModel=BoardModel.new()
 probe.setup(GameManager.config,GameManager.jokers,17)
 probe.fill_fresh()
 for cell: CandyState in probe.cells: cell.age=2
 probe.remove([56])
 probe.refill()
 probe.age_candies([])
 check(probe.cells[0].age==0 and probe.cells[56].age==0 and probe.cells[1].age==3,"Heatwave excludes newborn and falling tiles from this turn's aging")
 # Render maximal shop inventory: footer must be on screen with five sell buttons.
 GameManager.jokers.equipped.clear()
 for i: int in [0,1,4,8,12]: GameManager.jokers.add(GameManager.config.jokers[i])
 GameManager.score=999
 GameManager.settle_round()
 await get_tree().process_frame
 await get_tree().process_frame
 var shop: Control=main.get_node("Shop")
 var next_button: Control=shop.get_node("Actions/Continue")
 check(next_button.get_global_rect().end.y<=720,"Shop continue button fits viewport with five Jokers")
 check(shop.get_node("Offers").get_global_rect().end.x<=1152,"All shop offers fit on the table without scrolling")
 await capture("shop_full")
 GameManager.state="menu"
 main.to_menu()
 await capture("title")
 main.start()
 await capture("gameplay")
 main.show_codex()
 await capture("handbook")
 print("RESULT: %s effect/UI checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var target: String=OS.get_environment("SUGAR_CAPTURE_DIR")
 if not target.is_empty(): get_viewport().get_texture().get_image().save_png(target+"/"+name+".png")
