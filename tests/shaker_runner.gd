extends Node
var main: Control
var shop: Control
var failures: int = 0
var checks: int = 0
func check(value: bool, message: String) -> void:
 checks += 1
 if value: print("PASS: "+message)
 else:
  failures += 1
  push_error("FAIL: "+message)
func _ready() -> void:
 call_deferred("run_tests")
func frames() -> void:
 for i: int in range(3): await get_tree().process_frame
func click(control: Control) -> void:
 var logical: Vector2 = control.get_global_rect().get_center()
 var physical: Vector2 = Vector2(get_window().size)
 var factor: float = minf(physical.x/1152.0,physical.y/720.0)
 var point: Vector2 = (physical-Vector2(1152,720)*factor)*0.5+logical*factor
 var motion: InputEventMouseMotion = InputEventMouseMotion.new()
 motion.position = point
 motion.global_position = point
 get_window().push_input(motion,false)
 for pressed: bool in [true,false]:
  var event: InputEventMouseButton = InputEventMouseButton.new()
  event.position = point
  event.global_position = point
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
  get_window().push_input(event,false)
 await frames()
func run_tests() -> void:
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 main.start()
 GameManager.motion=false
 var board: GameBoard=main.get_node("Play/GameBoard")
 check(GameManager.shakers==0 and not GameManager.buy_shaker(),"Runs start with no consumables; buying is shop-only")
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 shop=main.get_node("Shop")
 GameManager.consumable_offers.assign(["sugar_shaker"])
 GameManager.gummies=20
 GameManager.changed.emit()
 for i: int in range(5): GameManager.jokers.add(GameManager.config.jokers[i])
 if not main.item_panel.visible: await click(shop.shaker_buy)
 await click(main.item_panel.buttons["sugar_shaker"])
 GameManager.consumable_offers.assign(["sugar_shaker"])
 main.item_panel.refresh()
 if not main.item_panel.visible: await click(shop.shaker_buy)
 await click(main.item_panel.buttons["sugar_shaker"])
 check(GameManager.shakers==2 and GameManager.gummies==12 and GameManager.jokers.equipped.size()==5,"Two physical purchases cost $8 and use no Joker slots")
 GameManager.consumable_offers.assign(["sugar_shaker"])
 main.item_panel.refresh()
 check(main.item_panel.buttons["sugar_shaker"].disabled and not GameManager.buy_shaker(),"Inventory cap blocks a third item without charging")
 await capture("shaker_shop")
 GameManager.shakers=1
 GameManager.gummies=3
 check(not GameManager.buy_shaker() and GameManager.shakers==1,"Insufficient cash cannot buy a consumable")
 GameManager.shakers=2
 GameManager.jokers.equipped.clear()
 main.close_items()
 GameManager.next_round()
 var before_cells: Array[CandyState]=board.model.cells.duplicate()
 var before_ids: Array[int]=[]
 for cell: CandyState in before_cells: before_ids.append(cell.get_instance_id())
 var moves: int=GameManager.moves
 var score: int=GameManager.score
 var streak: int=GameManager.streak
 await click(main.get_node("Play/Shaker"))
 await click(main.item_panel.buttons["sugar_shaker"])
 var after_ids: Array[int]=[]
 for cell: CandyState in board.model.cells: after_ids.append(cell.get_instance_id())
 before_ids.sort()
 after_ids.sort()
 check(GameManager.shakers==1 and GameManager.moves==moves and GameManager.score==score and GameManager.streak==streak,"Use consumes one item without changing moves, score or streak")
 check(before_ids==after_ids and before_cells!=board.model.cells,"Rearrangement preserves all candy objects and changes their positions")
 check(board.model.cells[18]==before_cells[18] and board.model.cells[45]==before_cells[45],"Framed candies remain anchored")
 check(board.model.matches().is_empty() and not board.model.legal_moves().is_empty(),"Shake ends with no automatic match and at least one legal move")
 await capture("shaker_gameplay")
 for dimensions: Vector2i in [Vector2i(800,500),Vector2i(720,960)]:
  get_window().size=dimensions
  GameManager.shakers=2
  GameManager.changed.emit()
  await frames()
  await click(main.get_node("Play/Shaker"))
  await click(main.item_panel.buttons["sugar_shaker"])
  check(GameManager.shakers==1,"Physical Shaker hitbox works at "+str(dimensions))
 var instruction: Control=main.get_node("Play/Instruction")
 check(instruction.position.y+instruction.get_minimum_size().y<main.get_node("Play/Shaker").position.y,"Instructions remain above the consumable button")
 get_window().size=Vector2i(1152,720)
 await frames()
 # Anchored Inspector candies, ages and coatings survive model shuffles.
 board.model.locked_color=0
 var anchored: Dictionary={}
 var coats: Dictionary={}
 for i: int in range(64):
  var cell: CandyState=board.model.cells[i]
  cell.age=i%4
  if i%7==0: cell.coating=2
  coats[cell.get_instance_id()]=[cell.coating,cell.age]
  if board.model.is_locked_tile(i): anchored[i]=cell
 check(board.model.shake_candies(),"Inspector board can be safely rearranged")
 var preserved: bool=true
 for i: int in anchored: preserved=preserved and board.model.cells[i]==anchored[i]
 for cell: CandyState in board.model.cells: preserved=preserved and coats[cell.get_instance_id()]==[cell.coating,cell.age]
 check(preserved,"Inspector locks, coatings and ages survive the shake")
 # No possible arrangement: keep the item and board exactly as they were.
 for cell: CandyState in board.model.cells: cell.blocker=2
 var locked: Array[CandyState]=board.model.cells.duplicate()
 board.request_shake()
 check(GameManager.shakers==1 and board.model.cells==locked and not board.busy,"Failed rearrangement keeps the item and original board")
 GameManager.round_index=17
 GameManager.start_round()
 GameManager.shakers=2
 GameManager.motion=true
 GameManager.changed.emit()
 var legal: Vector2i=board.model.legal_moves()[0]
 moves=GameManager.moves
 board.attempt_swap(legal.x,legal.y)
 board.request_shake()
 board.request_shake()
 check(board.shake_queued and GameManager.shakers==2,"Requests during animation queue without consuming early")
 while board.busy or board.shake_queued: await frames()
 await frames()
 while board.busy: await frames()
 check(GameManager.shakers==1 and GameManager.moves==moves-1,"Repeated queued requests use only one shaker and no extra move")
 board.shake_queued=true
 GameManager.state="shop"
 board.flush_shake_request()
 check(GameManager.shakers==1 and not board.shake_queued,"Round-end cancellation preserves the queued item")
 GameManager.state="playing"
 GameManager.shakers=2
 board.request_shake()
 main.toggle_pause()
 await get_tree().create_timer(0.2,true).timeout
 check(board.busy and GameManager.shakers==1,"Pausing a shake freezes it without consuming another item")
 await main.to_menu()
 check(GameManager.state=="menu" and not board.busy and not get_tree().paused,"Quit to Title during a shake completes without hanging")
 main.start()
 check(GameManager.shakers==0,"Starting a new run resets consumable inventory")
 print("RESULT: %s shaker checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(OS.get_environment("SUGAR_CAPTURE_DIR")+"/"+name+".png")
