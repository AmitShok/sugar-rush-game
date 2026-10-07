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
 main = preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 await capture("v3_title")
 main.get_node("Menu/Layout/Seed").text = "38038"
 main.start()
 GameManager.motion = false
 GameManager.jokers.equipped.assign([GameManager.config.jokers[4],GameManager.config.jokers[13]])
 GameManager.changed.emit()
 await frames()
 check(main.get_node("Play/UI_Hud").get_global_rect().end.y <= 710,"Larger-font HUD fits the game canvas")
 check(main.get_node("Menu").get_global_rect().end.y <= 710,"Larger-font title panel fits the canvas")
 await capture("v3_gameplay")
 GameManager.score = GameManager.current_round().quota+260
 GameManager.settle_round()
 GameManager.gummies = 40 # Explicit UI fixture, not a round payout.
 GameManager.offers.assign([GameManager.config.jokers[0],GameManager.config.jokers[9],GameManager.config.jokers[12],GameManager.config.jokers[1]])
 GameManager.changed.emit()
 shop = main.get_node("Shop")
 await frames()
 var descriptions_fit: bool = true
 for card: JokerData in GameManager.config.jokers:
  shop.inspect(card)
  await frames()
  descriptions_fit = descriptions_fit and shop.get_node("Details/Description").get_line_count() <= 2
 check(descriptions_fit,"All 22 descriptions fit the two-line detail area")
 check(main.get_node("Play/UI_Hud").is_visible_in_tree(),"Cash sidebar remains visible in the shop")
 check(main.get_node("Play/JokerInventory").is_visible_in_tree(),"Owned Jokers remain visible in the shop")
 check(not main.get_node("Play/GameBoard").is_visible_in_tree(),"Board is hidden while shopping")
 check(main.get_node("Play/UI_Hud/Layout/Wallet").text=="$40" and not shop.get_node("Wallet").visible,"One clear cash display shows the actual $40 wallet")
 var fits: bool = true
 for button: Button in shop.offer_buttons.values():
  fits = fits and button.get_global_rect().end.y <= 710 and button.get_global_rect().end.x <= 1144
 check(fits,"All four prices and Buy buttons are visible without scrolling")
 await click(shop.card_buttons["midas"])
 check(shop.selected.id=="midas" and shop.get_node("Details/Description").text==GameManager.config.jokers[9].description,"Selecting a card shows its exact rule")
 check(shop.get_node("Details/Status").text.contains("$28"),"Purchase preview shows cash remaining")
 await capture("v3_shop")
 await click(shop.offer_buttons["kaleidoscope"])
 check(GameManager.gummies==31 and GameManager.jokers.has("kaleidoscope"),"Visible Buy button purchases exactly its displayed $9 card")
 check(main.get_node("Play/UI_Hud/Layout/Wallet").text=="$31" and not shop.get_node("Wallet").visible,"The cash balance updates immediately after purchase")
 check(shop.get_node("Receipt").text.contains("-$9"),"Purchase receipt shows the cost")
 var owned_card: Control = main.get_node("Play/JokerInventory/Layout/Slots").get_child(0).get_child(0)
 await click(owned_card)
 check(shop.selected_owned and shop.selected.id=="gravity","Owned card opens a sell action")
 check(shop.get_node("Details/Action").text=="Sell +$5","Sell action explicitly displays refund")
 await click(shop.get_node("Details/Action"))
 check(GameManager.gummies==36 and not GameManager.jokers.has("gravity"),"Sale refunds exactly $5")
 var wallet: int = GameManager.gummies
 await click(shop.get_node("Actions/Reroll"))
 check(GameManager.gummies==wallet-3 and GameManager.reroll_cost==5,"Reroll deducts displayed cost and updates the next price")
 check(shop.get_node("Actions/Reroll").text.contains("$5"),"Next reroll price is visible")
 GameManager.gummies = 0
 GameManager.changed.emit()
 await frames()
 var disabled: bool = true
 for button: Button in shop.offer_buttons.values(): disabled = disabled and button.disabled
 check(disabled and shop.get_node("Actions/Reroll").disabled,"Unaffordable buys and rerolls are disabled")
 shop.inspect(GameManager.offers[0])
 check(shop.get_node("Details/Status").text.begins_with("Need $"),"Insufficient-cash explanation states the exact shortfall")
 GameManager.gummies = 500
 GameManager.jokers.equipped.assign([GameManager.config.jokers[4]])
 GameManager.offers.assign([GameManager.config.jokers[5]])
 GameManager.changed.emit()
 await frames()
 shop.inspect(GameManager.offers[0])
 check(not shop.offer_buttons["paintball"].disabled and shop.get_node("Details/Status").text.contains("Cash after"),"A second 4-match Joker can be bought without selling the first")
 for dimensions: Vector2i in [Vector2i(800,500),Vector2i(1280,720),Vector2i(720,960)]:
  get_window().size = dimensions
  await frames()
  check(shop.get_node("Actions/Continue").get_global_rect().end.y<=720 and shop.get_node("Details").get_global_rect().end.y<=720,"Shop layout stays on canvas at "+str(dimensions))
  await click(shop.get_node("Actions/Continue"))
  check(main.get_node("RoundMap").visible,"Next Round opens the route preview")
  await click(main.get_node("RoundMap").enter_button)
  check(GameManager.state=="playing" and main.get_node("Play/GameBoard").visible,"Physical Next Round hitbox works at "+str(dimensions))
  GameManager.score = GameManager.current_round().quota+50
  GameManager.settle_round()
  await frames()
 get_window().size = Vector2i(1152,720)
 main.to_menu()
 main.show_codex()
 await frames()
 await capture("v3_handbook")
 print("RESULT: %s shop/readability checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 var folder: String = OS.get_environment("SUGAR_CAPTURE_DIR")
 if not folder.is_empty(): get_viewport().get_texture().get_image().save_png(folder+"/"+name+".png")
