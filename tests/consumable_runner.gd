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
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 shop=main.get_node("Shop")
 GameManager.consumable_offers.assign(["extra_serving","golden_glaze"])
 GameManager.gummies=30
 GameManager.changed.emit()
 await click(shop.shaker_buy)
 var panel: Control=main.item_panel
 check(panel.visible and panel.buttons.size()==2,"Shop browser presents two offered consumables")
 await click(panel.buttons["extra_serving"])
 await click(panel.buttons["golden_glaze"])
 check(GameManager.consumables==["extra_serving","golden_glaze"] and GameManager.gummies==17,"Mixed purchases charge their exact prices")
 check(not GameManager.buy_shaker() and not GameManager.buy_consumable("candy_hammer"),"All types share one two-item cap")
 await frames()
 check(panel.cards.get_global_rect().end.x<=1112 and panel.cards.get_global_rect().end.y<546,"Card descriptions and actions fit the browser")
 await capture("consumable_shop")
 GameManager.discard_consumable(0)
 check(GameManager.consumables==["golden_glaze"] and GameManager.gummies==17,"Discard frees one slot without a refund")
 GameManager.consumable_offers.assign(["sugar_shaker"])
 check(GameManager.buy_shaker() and GameManager.consumables.size()==2,"Original Shaker shares slots with new cards")
 main.close_items()
 GameManager.next_round()
 var board: GameBoard=main.get_node("Play/GameBoard")
 GameManager.consumables.assign(["extra_serving","extra_serving"])
 GameManager.changed.emit()
 var moves: int=GameManager.moves
 await click(main.get_node("Play/Shaker"))
 await click(panel.buttons["extra_serving"])
 check(GameManager.moves==moves+2 and GameManager.consumables.size()==1,"Extra Serving adds two moves through the real inventory UI")
 board.request_consumable("extra_serving")
 check(GameManager.moves==moves+4 and GameManager.consumables.is_empty(),"Two Extra Servings stack once each")
 GameManager.consumables.assign(["golden_glaze","candy_hammer"])
 board.request_consumable("golden_glaze")
 check(board.target_consumable=="golden_glaze" and GameManager.consumables.size()==2,"Targeted card is not spent before choosing a candy")
 board.cancel_consumable_target()
 check(board.target_consumable.is_empty() and GameManager.consumables.size()==2,"Cancelling preserves the card")
 var color: int=board.model.cells[0].color
 board.model.cells[0].coating=0
 board.model.cells[1].color=color
 board.model.cells[1].coating=3
 var other: int=(color+1)%6
 board.model.cells[2].color=other
 board.model.cells[2].coating=0
 moves=GameManager.moves
 board.request_consumable("golden_glaze")
 board.sync_tiles(false)
 get_window().size=Vector2i(720,960)
 await frames()
 await click(board.tiles[0])
 var gold_ok: bool=true
 for cell: CandyState in board.model.cells:
  if cell.color==color and cell.coating!=3: gold_ok=gold_ok and cell.coating==2
 check(gold_ok and board.model.cells[1].coating==3 and board.model.cells[2].coating==0,"Glaze gilds only the chosen type and preserves Wilds")
 check(GameManager.consumables==["candy_hammer"] and GameManager.moves==moves,"Glaze consumes one card without spending a move")
 GameManager.consumables.append("golden_glaze")
 board.request_consumable("golden_glaze")
 board.choose(0)
 check("golden_glaze" in GameManager.consumables,"Glaze with no eligible candies keeps the item")
 board.cancel_consumable_target()
 # Isolate the direct hit from possible cascades; verify Roulette is not cleared by a smash.
 GameManager.start_round()
 GameManager.poison=0
 GameManager.poison_cleared=false
 board.model.cells.clear()
 for i: int in range(64):
  var candy: CandyState=CandyState.new((i%8+(i/8)*2)%6)
  candy.blocker=2
  board.model.cells.append(candy)
 board.model.cells[18].color=0
 board.model.cells[18].coating=2
 board.sync_tiles(false)
 var awards: Array[Dictionary]=[]
 var capture_award: Callable=func(result: Dictionary,_color: int) -> void: awards.append(result)
 board.matches_resolved.connect(capture_award)
 board.request_consumable("candy_hammer")
 board.choose(18)
 while board.busy: await frames()
 board.matches_resolved.disconnect(capture_award)
 check(not awards.is_empty() and awards[0].total==90 and awards[0].mult==1.0,"Hammer scores a gold candy plus its lock bonus without match multipliers")
 check(not GameManager.poison_cleared,"Hammer collateral is not a Roulette match")
 check("candy_hammer" not in GameManager.consumables and 18 in board.model.graves,"Hammer consumes once and destroys the targeted frame")
 GameManager.start_round()
 GameManager.consumables.assign(["extra_serving"])
 moves=GameManager.moves
 board.busy=true
 board.request_consumable("extra_serving")
 board.request_consumable("extra_serving")
 check(GameManager.moves==moves and GameManager.consumables.size()==1,"Busy-board requests do not consume early")
 board.busy=false
 board.flush_shake_request()
 await frames()
 check(GameManager.moves==moves+2 and GameManager.consumables.is_empty(),"Repeated queued requests consume once after resolution")
 GameManager.consumables.assign(["golden_glaze"])
 board.busy=true
 board.request_consumable("golden_glaze")
 board.busy=false
 GameManager.state="shop"
 board.flush_shake_request()
 await frames()
 check(GameManager.consumables==["golden_glaze"] and board.target_consumable.is_empty(),"Round ending keeps a queued targeted card")
 GameManager.start_run(99)
 check(GameManager.consumables.is_empty(),"New run clears every consumable type")
 print("RESULT: %s consumable checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(OS.get_environment("SUGAR_CAPTURE_DIR")+"/"+name+".png")
