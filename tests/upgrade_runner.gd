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
 # Since v0.28 candy upgrades come only from Candy Packs; the Candies tab only shows values.
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
 check(shop.upgrades_open and shop.candy_rows.size()==6 and not shop.get_node("Offers").visible,"Candies tab lists six types separately from Jokers")
 var has_buy: bool=false
 for row: HBoxContainer in shop.candy_rows:
  for child: Node in row.get_children(): has_buy=has_buy or child is Button
 check(not has_buy and shop.candy_rows[0].get_child(3).text=="From packs","Candies tab has no buy buttons and points to packs")
 check(not GameManager.has_method("buy_candy_upgrade"),"There is no direct candy purchase")
 var base: int=GameManager.config.candies[0].base_chips
 check(GameManager.level_candy(0) and GameManager.candy_value(0)==15 and GameManager.gummies==40,"A level adds half the base value and costs nothing by itself")
 GameManager.level_candy(0)
 check(GameManager.candy_value(0)==20 and GameManager.candy_value(1)==14,"Levels stack only on their type")
 check(GameManager.config.candies[0].base_chips==base,"Upgrades never mutate shared candy resources")
 check(not GameManager.level_candy(-1) and not GameManager.level_candy(6),"Invalid candy types are rejected")
 GameManager.changed.emit()
 await frames()
 check(shop.candy_rows[0].get_child(1).text.contains("Lv 2") and shop.candy_rows[0].get_child(2).text=="20 > 25","Candies tab shows level and current > next value")
 check(shop.get_node("Details/Description").get_minimum_size().y<=shop.get_node("Details/Status").position.y-shop.get_node("Details/Description").position.y,"Candy explanation fits the detail panel")
 await capture("candy_values")
 # Candy Packs are the source of upgrades.
 GameManager.opened_pack={}
 GameManager.pack_offers.assign([{"kind":"candy","jumbo":false,"free":false}])
 check(GameManager.open_pack(0) and GameManager.gummies==37,"Candy Pack opens for $3")
 var color: int=int(GameManager.opened_pack.choices[0].id)
 var before: int=GameManager.candy_value(color)
 GameManager.take_pack_card(0)
 check(GameManager.candy_value(color)==before+GameManager.upgrade_gain(color),"Taking a Candy Pack card upgrades that type")
 GameManager.next_round()
 check(GameManager.candy_value(0)==20,"Values persist into rounds")
 var board: GameBoard=main.get_node("Play/GameBoard")
 board.model.cells.clear()
 for i: int in range(64): board.model.cells.append(CandyState.new(1))
 for i: int in [0,1,2]: board.model.cells[i].color=0
 board.model.cells[1].blocker=1
 var group: Dictionary={"cells":[0,1,2],"color":0,"length":3,"shape":false,"diagonal":false,"axis":Vector2i.RIGHT}
 GameManager.jokers.clear_all()
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
 for i: int in range(100): GameManager.level_candy(0)
 check(GameManager.candy_level(0)==102,"Upgrades have no level cap")
 # A sixth Joker slot (Big Spoon) must fit inside the Joker bar.
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 GameManager.jokers.capacity=6
 for item: JokerData in GameManager.config.jokers:
  if GameManager.jokers.can_add(item): GameManager.jokers.add(item)
 GameManager.changed.emit()
 await frames()
 await frames()
 var bar: Control=main.get_node("Play/JokerInventory")
 var slots: Control=bar.get_node("Layout/Slots")
 var inside: bool=slots.get_global_rect().end.x<=bar.get_global_rect().end.x+0.5 and bar.get_global_rect().end.x<=1152
 for slot: Control in slots.get_children(): inside=inside and slot.get_global_rect().end.x<=bar.get_global_rect().end.x+0.5
 check(GameManager.jokers.equipped.size()==6 and slots.get_child_count()==6 and inside,"Six Joker slots fit inside the Joker bar")
 check(is_equal_approx(bar.get_global_rect().size.x,760.0),"The Joker bar keeps its width with six slots")
 await capture("six_jokers")
 GameManager.jokers.capacity=5
 for dimensions: Vector2i in [Vector2i(800,500),Vector2i(720,960),Vector2i(1600,700)]:
  get_window().size=dimensions
  await frames()
  await click(shop.joker_tab)
  await click(shop.upgrade_tab)
  check(shop.upgrades_open and shop.upgrade_rows.get_global_rect().end.x<=1152 and shop.get_node("Details").get_global_rect().end.y<=720,"Candies tab opens and fits at "+str(dimensions))
 GameManager.start_run(413)
 check(GameManager.candy_value(0)==10 and GameManager.candy_level(1)==0,"New run resets values and levels")
 print("RESULT: %s upgrade checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 var folder: String=OS.get_environment("SUGAR_CAPTURE_DIR")
 get_viewport().get_texture().get_image().save_png(folder+"/"+name+".png")
