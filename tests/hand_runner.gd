extends "res://tests/consumable_runner.gd"
# One move = one hand, and the exact move preview (v0.34).
func board_state(model: BoardModel) -> Array:
 var out: Array = []
 for cell: CandyState in model.cells:
  out.append([cell.color,cell.coating,cell.blocker,cell.special,cell.chocolate,cell.frosting] if cell != null else null)
 return [out,model.rng.state,model.jelly.duplicate(),model.isotopes.duplicate(),model.graves.duplicate()]

func run_tests() -> void:
 GameManager.preferences_path = "user://test_hand_preferences.cfg"
 main = preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 GameManager.start_run(3434)
 GameManager.motion = false
 main.start()
 await frames()
 var board: GameBoard = main.board
 var model: BoardModel = board.model
 var cfg: RunConfig = GameManager.config
 # --- Preview never changes the board ---
 var legal: Array[Vector2i] = model.legal_moves()
 var before: Array = board_state(model)
 var info: Dictionary = board.preview_info(legal[0].x,legal[0].y)
 check(bool(info.valid) and int(info.total) > 0 and not (info.cells as Array).is_empty(),"A legal swap previews a positive hand and the candies it clears")
 check(board_state(model) == before,"Previewing leaves the board, random state and obstacles untouched")
 # --- Preview is the exact floor: with no cascades the move scores exactly the preview ---
 var awards: Array[int] = []
 var record: Callable = func(result: Dictionary,_color: int) -> void: awards.append(int(result.total))
 board.matches_resolved.connect(record)
 var cap: int = cfg.cascade_limit
 cfg.cascade_limit = 1
 legal = model.legal_moves()
 info = board.preview_info(legal[0].x,legal[0].y)
 board.attempt_swap(legal[0].x,legal[0].y)
 while board.busy: await frames()
 check(awards.size() == 1 and awards[0] == int(info.total),"Without cascades a move scores exactly its preview (%s vs %s)" % [awards,info.total])
 cfg.cascade_limit = cap
 # --- With cascades the move can only score MORE than the preview ---
 var never_less: bool = true
 var one_award_each: bool = true
 for n: int in range(6):
  GameManager.moves = 20
  legal = model.legal_moves()
  if legal.is_empty(): break
  var pick: Vector2i = legal[n % legal.size()]
  info = board.preview_info(pick.x,pick.y)
  awards.clear()
  board.attempt_swap(pick.x,pick.y)
  while board.busy: await frames()
  one_award_each = one_award_each and awards.size() == 1
  never_less = never_less and not awards.is_empty() and awards[0] >= int(info.total)
  if GameManager.state != "playing": break
 check(one_award_each,"Each move awards exactly one hand, however many cascades it makes")
 check(never_less,"Cascades only add: no move scored less than its preview")
 board.matches_resolved.disconnect(record)
 # --- Joker multipliers apply once per move, not per group or wave ---
 var rules: JokerManager = JokerManager.new()
 rules.equipped.assign([GameManager.joker_by_id("labyrinth")])
 var hand: MoveHand = MoveHand.new()
 var g1: Dictionary = {"cells":[0,1,2,3],"color":0,"length":4,"diagonal":false,"shape":false,"axis":Vector2i.RIGHT}
 var g2: Dictionary = {"cells":[8,9,10,11],"color":1,"length":4,"diagonal":false,"shape":false,"axis":Vector2i.RIGHT}
 hand.add(g1,40,{"fired":[]},0,{},-1)
 hand.add(g2,40,{"fired":[]},0,{},-1)
 hand.add(g1.duplicate(),30,{"fired":[]},1,{},-1)
 var scored: Dictionary = hand.result(rules,0,false,64,{})
 # Candys 40+40+30 + Quad 10 = 120; Mult (Quad 2 + extra group 1 + cascade 0.5) x Labyrinth 3 = 10.5.
 check(int(scored.total) == 1260 and scored.recipe == "quad","Two Quads plus a cascade make one hand: 120 Candys x 10.5 Mult = 1260 (Labyrinth X3 once)")
 var early: MoveHand = MoveHand.new()
 early.add(g1,40,{"fired":[]},0,{},-1)
 check(int(early.result(rules,0,false,64,{}).total) <= int(scored.total),"Adding groups and waves never lowers a hand")
 # --- HUD shows the preview ---
 GameManager.start_round()
 await frames()
 legal = model.legal_moves()
 board.choose(legal[0].x)
 board.show_preview(legal[0].x,legal[0].y)
 await frames()
 var hud: Control = main.get_node("Play/UI_Hud")
 var expected: Dictionary = board.preview_info(legal[0].x,legal[0].y)
 check(hud.get_node("Layout/Equation").text.ends_with("= %s+" % UIStyle.short_number(int(expected.total))),"HUD shows the previewed hand and its guaranteed score")
 check(hud.get_node("Layout/Math/Chips").text == hud.number(float(expected.chips)) and hud.get_node("Layout/Math/Mult").text == hud.number(float(expected.mult)),"Candys x Mult boxes show the preview")
 var previewed: int = 0
 for tile: SugarTile in board.tiles:
  if tile.previewed: previewed += 1
 check(previewed == (expected.cells as Array).size(),"Board outlines exactly the candies the swap would clear")
 await capture("hand_preview")
 # An invalid neighbour previews the move cost.
 var bad: Vector2i = Vector2i(-1,-1)
 for i: int in range(model.cells.size()):
  for j: int in [i+1,i+8]:
   if j < model.cells.size() and model.adjacent(i,j) and not bool(board.preview_info(i,j).valid) and model.playable(i) and model.playable(j):
    bad = Vector2i(i,j)
    break
  if bad.x >= 0: break
 board.clear_preview()
 board.show_preview(bad.x,bad.y)
 await frames()
 check(hud.get_node("Layout/Equation").text == "NO MATCH  -1 MOVE","An invalid swap previews its cost")
 board.clear_preview()
 await frames()
 check(GameManager.preview.is_empty(),"Clearing the preview restores the HUD")
 # --- Touch drag: preview while held, release confirms, sliding back cancels ---
 board.selection = -1
 board.clear_preview()
 legal = model.legal_moves()
 var moves: int = GameManager.moves
 var from: Vector2 = board.global_position+Vector2(model.xy(legal[0].x))*56+Vector2(28,28)
 var to: Vector2 = board.global_position+Vector2(model.xy(legal[0].y))*56+Vector2(28,28)
 await touch(from,true)
 await drag(from,to)
 check(not GameManager.preview.is_empty() and GameManager.moves == moves and not board.busy,"Dragging toward a neighbour previews without swapping")
 await drag(to,from)
 check(GameManager.preview.is_empty(),"Sliding back cancels the preview")
 await touch(from,false)
 check(GameManager.moves == moves,"Releasing after sliding back does not swap")
 await touch(from,true)
 await drag(from,to)
 await touch(to,false)
 while board.busy: await frames()
 check(GameManager.moves == moves-1,"Releasing on the previewed neighbour swaps")
 DirAccess.remove_absolute(GameManager.preferences_path)
 print("RESULT: %s hand/preview checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)

func to_screen(logical: Vector2) -> Vector2:
 var size: Vector2 = Vector2(get_window().size)
 var factor: float = minf(size.x/1152.0,size.y/720.0)
 return (size-Vector2(1152,720)*factor)*0.5+logical*factor
func touch(point: Vector2, down: bool) -> void:
 var event: InputEventScreenTouch = InputEventScreenTouch.new()
 event.position = to_screen(point)
 event.pressed = down
 Input.parse_input_event(event)
 await frames()
func drag(a: Vector2, b: Vector2) -> void:
 var last: Vector2 = to_screen(a)
 for step: int in range(1,7):
  var event: InputEventScreenDrag = InputEventScreenDrag.new()
  event.position = to_screen(a.lerp(b,step/6.0))
  event.relative = event.position-last
  last = event.position
  Input.parse_input_event(event)
  await frames()
func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await RenderingServer.frame_post_draw
 var folder: String = OS.get_environment("SUGAR_CAPTURE_DIR")
 if not folder.is_empty(): get_viewport().get_texture().get_image().save_png(folder+"/"+name+".png")
