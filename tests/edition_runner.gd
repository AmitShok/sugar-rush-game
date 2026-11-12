extends "res://tests/upgrade_runner.gd"
# Joker editions, left-to-right Joker order, scaling Jokers, shop reordering and saves.
var cfg: RunConfig = preload("res://resources/default_run.tres")
func joker(id: String) -> JokerData:
 for item: JokerData in cfg.jokers:
  if item.id == id: return item
 return null
func trio() -> Dictionary:
 return {"cells":[0,1,2],"color":0,"length":3,"diagonal":false,"shape":false,"axis":Vector2i.RIGHT}
func run_tests() -> void:
 # Edition rolls.
 var counts: Dictionary={"":0,"foil":0,"holo":0,"poly":0}
 for i: int in range(20000): counts[EditionCatalog.roll([7,i])]+=1
 check(absf(counts.foil/20000.0-0.08)<0.01 and absf(counts.holo/20000.0-0.05)<0.01 and absf(counts.poly/20000.0-0.03)<0.01,"Editions roll at about 8% / 5% / 3%")
 check(EditionCatalog.roll([1,2,3])==EditionCatalog.roll([1,2,3]),"Edition rolls are deterministic")
 # Edition scoring.
 var rules: JokerManager=JokerManager.new()
 rules.add(joker("broken"))
 rules.equipped.clear()
 rules.add(joker("mobius"),"foil")
 check(ScoreEngine.calculate(30,trio(),false,rules,0,false,false,64,0).total==80,"Foil adds +50 Candys")
 rules.clear_all()
 rules.add(joker("mobius"),"holo")
 check(ScoreEngine.calculate(30,trio(),false,rules,0,false,false,64,0).total==150,"Holographic adds +4 Mult")
 rules.clear_all()
 rules.add(joker("mobius"),"poly")
 check(ScoreEngine.calculate(30,trio(),false,rules,0,false,false,64,0).total==45,"Polychrome gives x1.5 Mult")
 # Order matters: + before x beats x before +.
 rules.clear_all()
 rules.add(joker("addict"))
 rules.add(joker("labyrinth"))
 var plus_first: int=ScoreEngine.calculate(30,trio(),false,rules,2,false,false,64,0).total
 rules.clear_all()
 rules.add(joker("labyrinth"))
 rules.add(joker("addict"))
 var times_first: int=ScoreEngine.calculate(30,trio(),false,rules,2,false,false,64,0).total
 check(plus_first==30*(1+2)*3 and times_first==30*(1*3+2),"Jokers score left to right (Addict then Labyrinth beats the reverse)")
 rules.clear_all()
 rules.add(joker("mobius"),"poly")
 rules.add(joker("kaleidoscope"),"holo")
 var poly_first: int=ScoreEngine.calculate(30,trio(),false,rules,0,false,false,64,0).total
 rules.clear_all()
 rules.add(joker("kaleidoscope"),"holo")
 rules.add(joker("mobius"),"poly")
 var holo_first: int=ScoreEngine.calculate(30,trio(),false,rules,0,false,false,64,0).total
 check(poly_first==roundi(30*(1.5+4)) and holo_first==roundi(30*5*1.5),"Editions follow their Joker's position")
 check(rules.move(rules.equipped[1],-1) and rules.equipped[0].id=="mobius" and not rules.move(rules.equipped[0],-1),"Jokers can be moved within bounds")
 rules.remove(joker("mobius"))
 check(rules.edition("mobius").is_empty(),"Removing a Joker drops its edition")
 # Live game: scaling Jokers.
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 shop=main.get_node("Shop")
 GameManager.start_run(5150)
 GameManager.motion=false
 for id: String in ["sugar_cube","gumball_jar","candy_cane"]: GameManager.jokers.add(joker(id))
 GameManager.award({"chips":10,"mult":1,"total":10,"recipe":"quint","fired":0},0)
 GameManager.award({"chips":10,"mult":1,"total":10,"recipe":"shape","fired":3},0)
 GameManager.award({"chips":10,"mult":1,"total":10,"recipe":"trio","fired":2},0)
 check(GameManager.jokers.counter("sugar_cube")==2.0,"Sugar Cube grows +1 per Quint or Shape")
 check(is_equal_approx(GameManager.jokers.counter("candy_cane"),0.5),"Candy Cane grows x0.1 per special fired")
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 check(GameManager.jokers.counter("gumball_jar")==8.0,"Gumball Jar grows +8 per cleared round")
 var scored: int=ScoreEngine.calculate(30,trio(),false,GameManager.jokers,0,false,false,64,0).total
 check(scored==roundi((30+8)*(1+2)*1.5),"Scaling bonuses apply in Joker order")
 check(GameManager.scaling_status("candy_cane")=="Now: x1.5 Mult" and GameManager.joker_text(joker("sugar_cube")).contains("Now: +2 Mult"),"Descriptions show current growth")
 # Shop: editions on offers, price, buying, overlays, reorder buttons.
 GameManager.jokers.clear_all()
 GameManager.gummies=100
 GameManager.offers.assign([joker("midas"),joker("mobius"),joker("addict"),joker("labyrinth")])
 GameManager.offer_editions={"midas":"poly","mobius":"foil"}
 GameManager.changed.emit()
 await frames()
 check(GameManager.offer_price(joker("midas"))==joker("midas").price+5 and GameManager.offer_price(joker("addict"))==joker("addict").price,"Editions raise the offer price")
 check(shop.card_buttons["midas"].has_node("Edition") and not shop.card_buttons["addict"].has_node("Edition"),"Shop cards show the edition overlay")
 await click(shop.card_buttons["midas"])
 check(shop.get_node("Details/Name").text=="Midas Touch (Polychrome)" and shop.get_node("Details/Status").text.begins_with("x1.5 Mult"),"Details name the edition and its effect")
 await click(shop.offer_buttons["midas"])
 check(GameManager.jokers.edition("midas")=="poly" and GameManager.gummies==100-17,"Buying keeps the edition and charges the higher price")
 check(GameManager.sell_value(joker("midas"))==17/2,"Sell value includes the edition")
 await click(shop.offer_buttons["mobius"])
 await click(shop.offer_buttons["addict"])
 var slots: Node=main.get_node("Play/JokerInventory/Layout/Slots")
 await frames()
 check(slots.get_child(0).get_child(0).has_node("Edition") and not slots.get_child(2).get_child(0).has_node("Edition"),"Owned cards show their edition overlay")
 await click(slots.get_child(2).get_child(0))
 check(shop.selected_owned and shop.move_left.visible and shop.move_right.visible and shop.move_right.disabled,"Owned Joker shows move buttons; rightmost cannot move right")
 await click(shop.move_left)
 check(GameManager.jokers.equipped[1].id=="addict" and GameManager.jokers.equipped[2].id=="mobius","Move left reorders physically")
 await click(shop.move_left)
 check(GameManager.jokers.equipped[0].id=="addict" and shop.move_left.disabled,"Leftmost Joker cannot move further left")
 await capture("editions_shop")
 # Saves.
 GameManager.jokers.grow("addict",0.0)
 GameManager.jokers.add(joker("candy_cane"))
 GameManager.jokers.grow("candy_cane",0.7)
 var order: Array[String]=[]
 for item: JokerData in GameManager.jokers.equipped: order.append(item.id)
 main.run_save.checkpoint()
 GameManager.jokers.clear_all()
 GameManager.offer_editions.clear()
 check(main.run_save.restore(),"Run restores")
 var restored: Array[String]=[]
 for item: JokerData in GameManager.jokers.equipped: restored.append(item.id)
 check(restored==order and GameManager.jokers.edition("midas")=="poly" and GameManager.jokers.edition("mobius")=="foil" and is_equal_approx(GameManager.jokers.counter("candy_cane"),0.7),"Order, editions and growth survive save and Continue")
 GameManager.state="playing"
 check(not GameManager.move_joker(GameManager.jokers.equipped[1],-1),"Jokers can only be reordered in the shop")
 GameManager.start_run(5151)
 check(GameManager.jokers.editions.is_empty() and GameManager.jokers.counters.is_empty() and GameManager.offer_editions.is_empty(),"New run clears editions and growth")
 print("RESULT: %s edition/order/scaling checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
