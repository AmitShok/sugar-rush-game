extends "res://tests/consumable_runner.gd"
# Interactive title screen and Joker rarity odds (v0.33).
func click_at(logical: Vector2) -> void:
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
 GameManager.preferences_path = "user://test_title_preferences.cfg"
 main = preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 var title: Control = main.get_node("MenuBackdrop")
 var menu: PanelContainer = main.get_node("Menu")
 check(title.visible and menu.visible,"Title screen shows on start")
 check(menu.get_theme_stylebox("panel") is StyleBoxEmpty,"Title menu has no panel box")
 check(not menu.get_node("Layout/Title").visible and title.letters.size() == 10,"Animated SUGAR RUSH logo replaces the panel title")
 check(menu.get_global_rect().end.y <= 710 and menu.get_global_rect().position.y >= 250,"Buttons sit below the logo and fit the canvas %s" % menu.get_global_rect())
 # Wait for the intro, then capture the settled title.
 await get_tree().create_timer(1.2).timeout
 await capture("title_v033")
 var play: Control = menu.get_node("Layout/Play")
 check(is_equal_approx(play.modulate.a,1.0),"Intro finishes with buttons fully shown")
 # Tap a letter: it jumps.
 var letter: Label = title.letters[0]
 await click_at(letter.get_global_rect().get_center())
 check(title.letter_jump[0] > 0.5,"Tapping a logo letter makes it jump")
 # Tap a falling candy: it pops and the counter rises.
 GameManager.motion = false
 for other: Dictionary in title.candies.slice(1): (other.node as Control).position = Vector2(-200,-200)
 var entry: Dictionary = title.candies[0]
 var candy: Control = entry.node
 entry.speed = 0.0
 entry.spin = 0.0
 title.set_process(false)
 candy.size = Vector2(160,160)
 candy.rotation = 0.0
 candy.position = Vector2(960,40)
 await frames()
 await click_at(candy.get_global_rect().get_center())
 check(title.popped == 1 and entry not in title.candies,"Tapping a candy pops it")
 title.set_process(true)
 # Tap a card: it flips to a different Joker and shows its rarity.
 var card: Dictionary = title.cards[0]
 var before: JokerData = card.item
 await click_at((card.face as Control).get_global_rect().get_center())
 check(card.item != before,"Tapping a menu card flips it to another Joker")
 check((card.label as Label).text.contains(card.item.rarity.to_upper()),"Flipped card shows its rarity")
 # Starting a run hides the title layer.
 await click(play)
 await click(main.route.enter_button)
 check(not title.visible,"Title layer hides once a run starts")
 # Rarity data and odds.
 var tiers: Dictionary = {}
 for item: JokerData in GameManager.config.jokers: tiers[item.rarity] = int(tiers.get(item.rarity,0))+1
 check(tiers.size() == 4,"Jokers use all four rarity tiers")
 check(GameManager.joker_by_id("paintball").rarity == "Legendary","Paintball Splatter is Legendary")
 var random: RandomNumberGenerator = RandomNumberGenerator.new()
 random.seed = 38
 var pool: Array = GameManager.config.jokers.duplicate()
 var hits: Dictionary = {}
 for i: int in range(20000):
  var tier: String = (pool[JokerRarity.pick_index(pool,random)] as JokerData).rarity
  hits[tier] = int(hits.get(tier,0))+1
 for tier: String in JokerRarity.ORDER:
  var rate: float = float(hits.get(tier,0))/20000.0
  check(absf(rate-JokerRarity.chance(tier)) < 0.015,"%s rolls %.1f%% (target %.1f%%)" % [tier,rate*100.0,JokerRarity.chance(tier)*100.0])
 check(float(hits.get("Legendary",0)) < float(hits.get("Rare",0)) and float(hits.get("Rare",0)) < float(hits.get("Uncommon",0)) and float(hits.get("Uncommon",0)) < float(hits.get("Common",0)),"Rarer tiers roll less often")
 # Shop offers follow rarity: across many rolls Legendaries are the scarcest.
 GameManager.start_run(424242)
 var seen: Dictionary = {}
 for i: int in range(400):
  GameManager.roll_offers()
  for item: JokerData in GameManager.offers: seen[item.rarity] = int(seen.get(item.rarity,0))+1
 check(int(seen.get("Legendary",0)) > 0 and int(seen.get("Legendary",0)) < int(seen.get("Rare",0)),"Shop offers Legendaries least often (%s of %s)" % [seen.get("Legendary",0),400*4])
 # The shop's detail panel names the rarity with a coloured pill.
 GameManager.score = GameManager.current_round().quota
 GameManager.settle_round()
 await frames()
 var shop: Node = main.get_node("Shop")
 shop.inspect(GameManager.joker_by_id("paintball"))
 await frames()
 var pill: Control = shop.get_node("Details").get_node_or_null("RarityPill")
 check(pill != null and pill.get_child(0).text == "Legendary","Shop details show a Legendary pill for Paintball Splatter")
 check(pill != null and pill.get_global_rect().end.x < shop.get_node("Details/Action").get_global_rect().position.x,"Rarity pill does not cover the Buy button")
 await capture("shop_rarity")
 DirAccess.remove_absolute(GameManager.preferences_path)
 print("RESULT: %s title/rarity checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)

func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await RenderingServer.frame_post_draw
 var folder: String = OS.get_environment("SUGAR_CAPTURE_DIR")
 if not folder.is_empty(): get_viewport().get_texture().get_image().save_png(folder+"/"+name+".png")
