extends Node
var failures: int=0
var checks: int=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if ok: print("PASS: "+message)
 else:
  failures+=1
  push_error("FAIL: "+message)
func _ready() -> void:
 call_deferred("run_tests")
func click(point: Vector2) -> void:
 var dimensions: Vector2=Vector2(get_window().size)
 var factor: float=minf(dimensions.x/1152.0,dimensions.y/720.0)
 var physical: Vector2=(dimensions-Vector2(1152,720)*factor)*0.5+point*factor
 for pressed: bool in [true,false]:
  var event: InputEventMouseButton=InputEventMouseButton.new()
  event.position=physical
  event.global_position=physical
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=pressed
  get_window().push_input(event,false)
 await get_tree().process_frame
func run_tests() -> void:
 var main: Control=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await get_tree().process_frame
 for animated: bool in [false,true]:
  main.start()
  GameManager.motion=animated
  var board: GameBoard=main.get_node("Play/GameBoard")
  board.model.cells.clear()
  board.model.graves.clear()
  board.model.locked_color=5
  for i: int in range(64): board.model.cells.append(CandyState.new((i%8+i/8*2)%6))
  board.model.cells[24].color=0
  board.model.cells[25].color=0
  board.model.cells[26].color=1
  board.model.cells[34].color=0
  board.model.cells[17].color=3
  board.model.cells[17].blocker=2
  board.model.cells[33].color=5
  var blocked: CandyState=board.model.cells[17]
  var locked: CandyState=board.model.cells[33]
  board.sync_tiles(false)
  check(board.model.matches().is_empty(),"Fixture starts without a match")
  var awards: Array[int]=[]
  var record: Callable=func(result: Dictionary,_color: int) -> void: awards.append(result.total)
  board.matches_resolved.connect(record)
  await get_tree().process_frame
  await click(board.position+Vector2(board.model.xy(26))*56+Vector2(28,28))
  await click(board.position+Vector2(board.model.xy(34))*56+Vector2(28,28))
  while board.busy: await get_tree().process_frame
  board.matches_resolved.disconnect(record)
  check(blocked not in board.model.cells and locked not in board.model.cells,"Physical three-match breaks both neighboring blocker and Inspector candy; animation="+str(animated))
  check(not awards.is_empty() and awards[0]==150,"Three-match awards 30 + 30 + 70 candy value and two 10-point bonuses")
  check(GameManager.moves==9 and 17 in board.model.graves,"Swap spends one move and records the destroyed blocker")
 # Include the trapped candy itself in the completed line, using physical input.
 for animated: bool in [false,true]:
  for kind: String in ["frame","inspector"]:
   for length: int in [3,4,5]:
    main.start()
    GameManager.motion=animated
    var board: GameBoard=main.get_node("Play/GameBoard")
    board.model.cells.clear()
    board.model.graves.clear()
    board.model.locked_color=0 if kind=="inspector" else -1
    for i: int in range(64): board.model.cells.append(CandyState.new((i%8+i/8*2)%6))
    for i: int in range(24,24+length): board.model.cells[i].color=0
    board.model.cells[26].color=1
    board.model.cells[34].color=0
    if kind=="frame": board.model.cells[25].blocker=2
    var trapped: CandyState=board.model.cells[25]
    board.sync_tiles(false)
    check(board.model.matches().is_empty(),"Direct-match fixture is stable: "+kind+str(length))
    var awards: Array[int]=[]
    var record: Callable=func(result: Dictionary,_color: int) -> void: awards.append(result.total)
    board.matches_resolved.connect(record)
    await click(board.position+Vector2(board.model.xy(26))*56+Vector2(28,28))
    await click(board.position+Vector2(board.model.xy(34))*56+Vector2(28,28))
    while board.busy: await get_tree().process_frame
    board.matches_resolved.disconnect(record)
    check(trapped not in board.model.cells and GameManager.moves==9,"Physical match %s includes and destroys %s candy, motion=%s" % [length,kind,animated])
    check(not awards.is_empty() and awards[0]>length*10,"Direct locked match scores its breaking bonus")
    if kind=="frame" and length==3: check(awards[0]==40,"Direct three-match scores 30 Candys plus 10 for the framed candy")
 print("RESULT: %s physical locked-tile checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
