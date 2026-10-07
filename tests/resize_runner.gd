extends Node
var failures: int = 0
var checks: int = 0
var main: Control
var board: GameBoard
func check(value: bool, message: String) -> void:
 checks += 1
 if value: print("PASS: "+message)
 else:
  failures += 1
  push_error("FAIL: "+message)
func _ready() -> void:
 call_deferred("run_tests")
func physical_point(logical: Vector2) -> Vector2:
 # Independently project the 1152x720 design into the physical client area.
 var physical: Vector2=Vector2(get_window().size)
 var factor: float=minf(physical.x/1152.0,physical.y/720.0)
 return (physical-Vector2(1152,720)*factor)*0.5+logical*factor
func click(logical: Vector2) -> void:
 var point: Vector2=physical_point(logical)
 var motion: InputEventMouseMotion=InputEventMouseMotion.new()
 motion.position=point
 motion.global_position=point
 get_window().push_input(motion,false)
 for pressed: bool in [true,false]:
  var event: InputEventMouseButton=InputEventMouseButton.new()
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=pressed
  event.position=point
  event.global_position=point
  get_window().push_input(event,false)
 await get_tree().process_frame
func click_cell(i: int) -> void:
 await click(board.position+Vector2(board.model.xy(i))*board.cell_size+Vector2.ONE*28)
func settle_frames() -> void:
 for i: int in range(4): await get_tree().process_frame
func run_tests() -> void:
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await settle_frames()
 main.get_node("Menu/Layout/Seed").text="38038"
 main.start()
 board=main.get_node("Play/GameBoard")
 GameManager.motion=false
 var sizes: Array[Vector2i]=[Vector2i(1152,720),Vector2i(800,500),Vector2i(1280,720),Vector2i(1440,900),Vector2i(960,720),Vector2i(720,960),Vector2i(1600,700),Vector2i(640,400)]
 for dimensions: Vector2i in sizes:
  get_window().size=dimensions
  await settle_frames()
  var correct: bool=true
  var clicked: int=0
  for i: int in range(64):
   if not board.model.playable(i): continue
   board.selection=-1
   await click_cell(i)
   if board.selection!=i:
    print("CLICK MISMATCH: ",dimensions," expected ",i," selected ",board.selection," final=",get_window().get_final_transform()," stretch=",get_window().get_stretch_transform())
    correct=false
    break
   clicked+=1
  check(correct and clicked==62,"All 62 unlocked cells select correctly at "+str(dimensions))
  check(main.get_node("Play/UI_Hud").get_global_rect().end.y<=720 and main.get_node("Play/MenuButton").get_global_rect().end.y<=720,"HUD and footer remain inside logical canvas at "+str(dimensions))
  board.selection=-1
  var legal: Array[Vector2i]=board.model.legal_moves()
  var moves: int=GameManager.moves
  await click_cell(legal[0].x)
  await click_cell(legal[0].y)
  while board.busy: await get_tree().process_frame
  check(GameManager.moves==moves-1 and GameManager.score>0,"Physical pointer swap resolves at "+str(dimensions))
  GameManager.start_run(38038)
  await settle_frames()
 # Resize in the middle of an animation, then verify visual/model alignment.
 get_window().size=Vector2i(1152,720)
 await settle_frames()
 GameManager.motion=true
 var legal: Array[Vector2i]=board.model.legal_moves()
 await click_cell(legal[0].x)
 await click_cell(legal[0].y)
 get_window().size=Vector2i(900,600)
 while board.busy: await get_tree().process_frame
 await get_tree().create_timer(0.35).timeout
 var aligned: bool=true
 for i: int in range(64):
  aligned=aligned and board.tiles[i].position.is_equal_approx(Vector2(board.model.xy(i))*board.cell_size)
 check(aligned,"Every sprite aligns with its cell after resize during a live cascade")
 board.selection=-1
 await click_cell(63)
 check(board.selection==63,"Bottom-right candy still receives its own click after animated resize")
 await click(main.get_node("Play/MenuButton").get_global_rect().get_center())
 check(board.paused and main.get_node("Pause").visible,"Options button uses correct resized hitbox")
 main.toggle_pause()
 main.show_codex()
 board.selection=-1
 await click_cell(0)
 check(board.selection==-1,"Modal blocks clicks on resized board")
 main.close_codex()
 get_window().size=Vector2i(1152,720)
 GameManager.start_run(38038)
 GameManager.motion=false
 GameManager.jokers.equipped.assign([GameManager.config.jokers[0],GameManager.config.jokers[4],GameManager.config.jokers[8]])
 GameManager.changed.emit()
 await settle_frames()
 await capture("redesigned_gameplay")
 GameManager.score=1000
 GameManager.settle_round()
 await settle_frames()
 await capture("redesigned_shop")
 check(main.get_node("Shop/Actions/Continue").get_global_rect().end.y<=720,"Shop footer stays visible with new font and art")
 GameManager.jokers.equipped.clear()
 GameManager.changed.emit()
 await settle_frames()
 var offer: JokerData=GameManager.offers[0]
 var before_wallet: int=GameManager.gummies
 var offers: HBoxContainer=main.get_node("Shop/Offers")
 var buy: Button=main.get_node("Shop").offer_buttons[offer.id] as Button
 await click(buy.get_global_rect().get_center())
 check(GameManager.jokers.has(offer.id) and GameManager.gummies==before_wallet-offer.price,"Physical shop Buy hitbox purchases the card under the pointer")
 await click(main.get_node("Shop/Actions/Continue").get_global_rect().get_center())
 await click(main.get_node("RoundMap").enter_button.get_global_rect().get_center())
 check(GameManager.state=="playing" and GameManager.round_index==1,"Physical Continue hitbox opens the next batch")
 print("RESULT: %s resize/input checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
func capture(name: String) -> void:
 await RenderingServer.frame_post_draw
 var folder: String=OS.get_environment("SUGAR_CAPTURE_DIR")
 if not folder.is_empty(): get_viewport().get_texture().get_image().save_png(folder+"/"+name+".png")
