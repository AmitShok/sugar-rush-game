extends "res://tests/consumable_runner.gd"
func tap(control: Control) -> void:
 await tap_point(control.get_global_rect().get_center())
func tap_point(logical: Vector2) -> void:
 var size: Vector2=Vector2(get_window().size)
 var factor: float=minf(size.x/1152.0,size.y/720.0)
 var point: Vector2=(size-Vector2(1152,720)*factor)*0.5+logical*factor
 for down: bool in [true,false]:
  var event: InputEventScreenTouch=InputEventScreenTouch.new()
  event.position=point
  event.index=0
  event.pressed=down
  Input.parse_input_event(event)
  await frames()
func to_screen(logical: Vector2) -> Vector2:
 var size: Vector2=Vector2(get_window().size)
 var factor: float=minf(size.x/1152.0,size.y/720.0)
 return (size-Vector2(1152,720)*factor)*0.5+logical*factor
# Finger down at a, slide to b in steps, lift.
func swipe(a: Vector2, b: Vector2) -> void:
 var down: InputEventScreenTouch=InputEventScreenTouch.new()
 down.position=to_screen(a)
 down.pressed=true
 Input.parse_input_event(down)
 await frames()
 var last: Vector2=to_screen(a)
 for step: int in range(1,7):
  var drag: InputEventScreenDrag=InputEventScreenDrag.new()
  drag.position=to_screen(a.lerp(b,step/6.0))
  drag.relative=drag.position-last
  last=drag.position
  Input.parse_input_event(drag)
  await frames()
 var up: InputEventScreenTouch=InputEventScreenTouch.new()
 up.position=last
 up.pressed=false
 Input.parse_input_event(up)
 await frames()
func mouse_drag(a: Vector2, b: Vector2) -> void:
 var press: InputEventMouseButton=InputEventMouseButton.new()
 press.button_index=MOUSE_BUTTON_LEFT
 press.pressed=true
 press.position=to_screen(a)
 press.global_position=press.position
 Input.parse_input_event(press)
 await frames()
 for step: int in range(1,7):
  var motion: InputEventMouseMotion=InputEventMouseMotion.new()
  motion.position=to_screen(a.lerp(b,step/6.0))
  motion.global_position=motion.position
  motion.button_mask=MOUSE_BUTTON_MASK_LEFT
  Input.parse_input_event(motion)
  await frames()
 var release: InputEventMouseButton=InputEventMouseButton.new()
 release.button_index=MOUSE_BUTTON_LEFT
 release.pressed=false
 release.position=to_screen(b)
 release.global_position=release.position
 Input.parse_input_event(release)
 await frames()
func run_tests() -> void:
 GameManager.preferences_path="user://test_touch_preferences.cfg"
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 check(Input.emulate_mouse_from_touch,"Touch-to-mouse emulation is enabled")
 await tap(main.get_node("Menu/Layout/Play"))
 check(main.route.visible,"Touch opens the route preview")
 await tap(main.route.enter_button)
 check(GameManager.state=="playing","Touch starts a round")
 GameManager.motion=false
 var board: GameBoard=main.board
 # Use a late high-quota round (not the last) so test swaps never finish the round early.
 GameManager.round_index=16
 GameManager.start_round()
 await frames()
 for size: Vector2i in [Vector2i(1152,720),Vector2i(844,390),Vector2i(720,960)]:
  get_window().size=size
  await frames()
  board.selection=-1
  var pair: Vector2i=board.model.legal_moves()[0]
  var moves: int=GameManager.moves
  await tap_point(board.global_position+Vector2(board.model.xy(pair.x))*56+Vector2(28,28))
  check(board.selection==pair.x,"Touch selects the correct cell at %s" % size)
  await tap_point(board.global_position+Vector2(board.model.xy(pair.y))*56+Vector2(28,28))
  while board.busy: await frames()
  check(GameManager.moves==moves-1,"Two taps spend exactly one move at %s" % size)
  if GameManager.state=="shop": GameManager.next_round()
 # Drag-to-swap with a finger at several screen shapes, then with a mouse.
 GameManager.moves=20
 for size: Vector2i in [Vector2i(1152,720),Vector2i(844,390),Vector2i(720,960)]:
  get_window().size=size
  await frames()
  if GameManager.state=="shop": GameManager.next_round()
  board.selection=-1
  var pair: Vector2i=board.model.legal_moves()[0]
  var moves: int=GameManager.moves
  var from: Vector2=board.global_position+Vector2(board.model.xy(pair.x))*56+Vector2(28,28)
  var to: Vector2=board.global_position+Vector2(board.model.xy(pair.y))*56+Vector2(28,28)
  await swipe(from,from+(to-from)*0.2)
  check(GameManager.moves==moves and not board.busy,"A short wiggle does not swap at %s" % size)
  board.selection=-1
  await swipe(from,to)
  while board.busy: await frames()
  check(GameManager.moves==moves-1 and board.selection==-1,"One touch drag swaps and spends one move at %s" % size)
 get_window().size=Vector2i(1152,720)
 await frames()
 if GameManager.state=="shop": GameManager.next_round()
 board.selection=-1
 var mouse_pair: Vector2i=board.model.legal_moves()[0]
 var mouse_moves: int=GameManager.moves
 await mouse_drag(board.global_position+Vector2(board.model.xy(mouse_pair.x))*56+Vector2(28,28),board.global_position+Vector2(board.model.xy(mouse_pair.y))*56+Vector2(28,28))
 while board.busy: await frames()
 check(GameManager.moves==mouse_moves-1,"A mouse drag swaps candies")
 var roulette: JokerData=load("res://resources/jokers/roulette.tres")
 GameManager.jokers.add(roulette)
 GameManager.poison=2
 GameManager.changed.emit()
 await frames()
 var card: Control=main.get_node("Play/JokerInventory/Layout/Slots").get_child(0).get_child(0)
 await tap(card)
 check(is_instance_valid(main.joker_details) and board.paused,"Touch opens owned Joker details and blocks board input")
 var panel: Node=main.joker_details.get_child(1).get_child(0)
 check(panel.get_child(1).text.contains("Mint Gummy"),"Touch details include the current Roulette candy")
 await tap(panel.get_node("Close"))
 check(not is_instance_valid(main.joker_details) and not board.paused,"Touch closes the Joker details")
 await tap(main.get_node("Play/MenuButton"))
 check(get_tree().paused,"Touch opens pause")
 await tap(main.get_node("Pause/Layout/Resume"))
 check(not get_tree().paused,"Touch resumes")
 await tap(main.get_node("Play/MenuButton"))
 await tap(main.get_node("Pause/Layout/Options"))
 await tap(main.get_node("Pause/Layout/Volume/Slider"))
 check(absf(GameManager.master_volume-0.5)<0.1,"Touch adjusts the volume slider")
 await tap(main.get_node("Pause/Layout/Back"))
 await tap(main.get_node("Pause/Layout/Resume"))
 GameManager.poison_cleared=true
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 GameManager.gummies=30
 await frames()
 await tap(main.get_node("Shop").shaker_buy)
 var id: String=GameManager.consumable_offers[0]
 await tap(main.item_panel.buttons[id])
 check(GameManager.consumables==[id],"Touch purchases a consumable exactly once")
 await tap(main.item_panel.get_node("Back"))
 check(not main.item_panel.visible,"Touch closes the consumable browser")
 DirAccess.remove_absolute(GameManager.preferences_path)
 print("RESULT: %s touch checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
