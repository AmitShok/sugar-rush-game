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
 GameManager.start_run(412)
 GameManager.motion=false
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 shop=main.get_node("Shop")
 GameManager.gummies=40
 GameManager.changed.emit()
 await click(shop.upgrade_tab)
 check(shop.upgrades_open and shop.upgrade_buttons.size()==6 and not shop.get_node("Offers").visible,"Upgrade tab shows six types separately from Jokers")
 var base: int=GameManager.config.candies[0].base_chips
 await click(shop.upgrade_buttons[0])
 check(GameManager.gummies==36 and GameManager.candy_value(0)==15 and GameManager.upgrade_cost(0)==6,"First physical purchase charges $4 and adds five Candys")
 await click(shop.upgrade_buttons[0])
 check(GameManager.gummies==30 and GameManager.candy_value(0)==20 and GameManager.candy_value(1)==14,"Repeat purchases stack only on their type and cost $6 next")
 check(GameManager.config.candies[0].base_chips==base,"Purchases never mutate shared candy resources")
 for i: int in range(5): GameManager.jokers.add(GameManager.config.jokers[i])
 check(GameManager.buy_candy_upgrade(1) and GameManager.jokers.equipped.size()==5,"Full Joker inventory does not block upgrades")
 await frames()
 check(shop.get_node("Details/Description").get_minimum_size().y<=shop.get_node("Details/Status").position.y-shop.get_node("Details/Description").position.y,"Upgrade explanation fits the detail panel")
 await capture("candy_upgrades")
 GameManager.gummies=0
 GameManager.changed.emit()
 check(shop.upgrade_buttons[0].disabled and not GameManager.buy_candy_upgrade(0),"Unaffordable upgrade is disabled and cannot be bought")
 check(not GameManager.buy_candy_upgrade(-1) and not GameManager.buy_candy_upgrade(6),"Invalid candy types are rejected")
 GameManager.next_round()
 check(GameManager.candy_value(0)==20 and not GameManager.buy_candy_upgrade(0),"Values persist into rounds and purchases are shop-only")
 var board: GameBoard=main.get_node("Play/GameBoard")
 board.model.cells.clear()
 for i: int in range(64): board.model.cells.append(CandyState.new(1))
 for i: int in [0,1,2]: board.model.cells[i].color=0
 board.model.cells[1].blocker=1
 var group: Dictionary={"cells":[0,1,2],"color":0,"length":3,"shape":false,"diagonal":false,"axis":Vector2i.RIGHT}
 GameManager.jokers.equipped.clear()
 var effect: Dictionary=board.model.expand(group)
 check(effect.chips==70,"Live board scores upgraded values plus locked-tile bonus")
 board.model.cells[0].coating=2
 board.model.cells[1].coating=1
 effect=board.model.expand(group)
 check(effect.chips==160,"Gold and caramel retain the type upgrade, including trapped candies")
 check(board._get_tooltip(Vector2(20,20)).contains("90 Candys"),"Hover text reports upgraded coated value")
 var guide: Control=main.get_node("CandyGuide")
 guide.show_candies()
 check(guide.rows.get_child(0).get_child(2).text=="20","Candy Guide reports current run values")
 guide.hide()
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 GameManager.gummies=100000
 for i: int in range(100): GameManager.buy_candy_upgrade(0)
 check(GameManager.candy_level(0)==102,"Upgrades have no purchase-count or slot cap")
 GameManager.changed.emit()
 for dimensions: Vector2i in [Vector2i(800,500),Vector2i(720,960),Vector2i(1600,700)]:
  get_window().size=dimensions
  await frames()
  await click(shop.joker_tab)
  await click(shop.upgrade_tab)
  var before: int=GameManager.candy_level(2)
  await click(shop.upgrade_buttons[2])
  check(GameManager.candy_level(2)==before+1,"Physical upgrade purchase stays aligned at "+str(dimensions))
  check(shop.upgrade_rows.get_global_rect().end.x<=1152 and shop.get_node("Details").get_global_rect().end.y<=720,"Upgrade UI fits resized viewport")
 GameManager.start_run(413)
 check(GameManager.candy_value(0)==10 and GameManager.candy_level(1)==0 and GameManager.upgrade_cost(0)==4,"New run resets values, levels and prices")
 print("RESULT: %s upgrade checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 var folder: String=OS.get_environment("SUGAR_CAPTURE_DIR")
 get_viewport().get_texture().get_image().save_png(folder+"/"+name+".png")
