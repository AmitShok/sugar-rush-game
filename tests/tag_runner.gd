extends "res://tests/upgrade_runner.gd"
# Interest, skip Tags and their effects, closed shops after skipping, the route Skip button and saves.
func win_round() -> void:
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
func run_tests() -> void:
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 shop=main.get_node("Shop")
 # Interest.
 GameManager.start_run(4100)
 GameManager.motion=false
 GameManager.gummies=23
 GameManager.moves=0
 win_round()
 check(GameManager.last_interest==4 and GameManager.gummies==23+5+4,"Interest pays $1 per $5 held, before the round payout")
 check(GameManager.last_summary.contains("interest $4"),"Round summary lists interest")
 GameManager.next_round()
 GameManager.gummies=300
 GameManager.moves=0
 win_round()
 check(GameManager.last_interest==5,"Interest is capped at $5")
 # Tag selection.
 var valid: bool=true
 for i: int in range(18): valid=valid and TagCatalog.ITEMS.has(TagCatalog.for_round(77,i)) and TagCatalog.for_round(77,i)==TagCatalog.for_round(77,i)
 check(valid,"Every round has a deterministic Tag from the run seed")
 var varied: Dictionary={}
 for s: int in range(40): varied[TagCatalog.for_round(s,0)]=true
 check(varied.size()==TagCatalog.ORDER.size(),"All six Tags can appear")
 check(TagCatalog.skippable(0) and TagCatalog.skippable(4) and not TagCatalog.skippable(2) and not TagCatalog.skippable(17),"Small and Big batches can be skipped; Bosses cannot")
 # Skipping from the shop.
 GameManager.start_run(4200)
 win_round()
 var cash: int=GameManager.gummies
 check(GameManager.can_skip() and GameManager.skip_target()==1,"From the shop, the next Big batch can be skipped")
 var tag: String=GameManager.skip_round()
 check(tag==GameManager.tag_for(1) and GameManager.round_index==1 and GameManager.state=="shop" and GameManager.shop_closed,"Skipping claims that round's Tag and moves past it")
 check(GameManager.offers.is_empty() and GameManager.consumable_offers.is_empty() and GameManager.last_award==0,"A skipped round pays no cash and stocks no shop")
 check(GameManager.tags_claimed==[tag],"Claimed Tags are recorded")
 if tag != "piggy" and tag != "sweets": check(GameManager.gummies==cash,"Skipping itself costs nothing")
 GameManager.gummies=50
 check(not GameManager.can_open_pack(0) and GameManager.pack_offers.is_empty(),"Closed shop has no packs to open")
 var before_offers: int=GameManager.offers.size()
 GameManager.reroll()
 check(GameManager.gummies==50 and GameManager.offers.size()==before_offers,"Closed shop refuses rerolls")
 check(not GameManager.can_skip(),"The Boss after a skip cannot be skipped")
 GameManager.next_round()
 check(GameManager.round_index==2 and GameManager.state=="playing" and not GameManager.shop_closed,"Next goes on to the following round")
 win_round()
 check(not GameManager.shop_closed and not GameManager.offers.is_empty(),"The next cleared round opens a normal shop")
 # Fresh-round skip (new run) and no skip after moving.
 GameManager.start_run(4300)
 check(GameManager.skip_target()==0 and GameManager.can_skip(),"An untouched opening round can be skipped")
 GameManager.begin_move(true)
 check(not GameManager.can_skip(),"A round cannot be skipped after a move")
 # Each Tag effect.
 GameManager.start_run(4400)
 win_round()
 GameManager.gummies=10
 GameManager.apply_tag("piggy")
 check(GameManager.gummies==20,"Piggy doubles cash")
 GameManager.gummies=40
 GameManager.apply_tag("piggy")
 check(GameManager.gummies==55,"Piggy is capped at +$15")
 var levels: int=0
 for id: String in RecipeCatalog.ORDER: levels+=GameManager.recipe_level(id)
 GameManager.apply_tag("cookbook")
 var after: int=0
 for id: String in RecipeCatalog.ORDER: after+=GameManager.recipe_level(id)
 check(after==levels+2 and GameManager.recipe_level("diagonal")==1,"Cookbook raises two different non-diagonal recipes")
 GameManager.consumables.clear()
 GameManager.apply_tag("sweets")
 check(GameManager.consumables.size()==1 and ConsumableCatalog.ITEMS.has(GameManager.consumables[0]),"Sweets grants a consumable")
 GameManager.consumables.assign(["sugar_shaker","sugar_shaker"])
 GameManager.gummies=0
 GameManager.apply_tag("sweets")
 check(GameManager.gummies==4 and GameManager.consumables.size()==2,"Sweets pays $4 when items are full")
 GameManager.apply_tag("reroll")
 GameManager.gummies=10
 var cost_before: int=GameManager.reroll_cost
 GameManager.reroll()
 GameManager.reroll()
 check(GameManager.gummies==10 and GameManager.free_rerolls==0 and GameManager.reroll_cost==cost_before,"Reroll Tag gives two free rerolls without raising the price")
 GameManager.reroll()
 check(GameManager.gummies==10-cost_before,"Rerolls cost money again afterwards")
 GameManager.apply_tag("handout")
 GameManager.reroll_cost=0
 GameManager.roll_offers()
 var free_item: JokerData=GameManager.offers[0]
 check(GameManager.offer_price(free_item)==0 and GameManager.offer_price(GameManager.offers[1])==GameManager.offers[1].price,"Handout makes exactly one offer free")
 GameManager.jokers.equipped.clear()
 GameManager.gummies=0
 check(GameManager.buy(free_item) and GameManager.gummies==0,"The free Joker can be taken with no cash")
 check(GameManager.sell_value(free_item)==0,"A free Joker sells for $0")
 GameManager.sell(free_item)
 check(GameManager.gummies==0 and GameManager.free_owned.is_empty(),"Selling it pays nothing")
 GameManager.apply_tag("moves")
 GameManager.next_round()
 check(GameManager.moves==GameManager.current_round().moves+3 and GameManager.bonus_moves==0,"Extra Moves adds 3 moves to the next round only")
 check(GameManager.can_skip(),"A round with extra moves is still untouched and skippable")
 GameManager.skip_round()
 GameManager.next_round()
 check(GameManager.moves==GameManager.current_round().moves+3,"Skipping an untouched round keeps its extra moves")
 # Saves.
 GameManager.free_rerolls=1
 GameManager.bonus_moves=3
 GameManager.free_owned.assign(["mobius"])
 GameManager.tags_claimed.assign(["piggy","moves"])
 GameManager.shop_closed=false
 main.run_save.checkpoint()
 GameManager.free_rerolls=0
 GameManager.bonus_moves=0
 GameManager.free_owned.clear()
 GameManager.tags_claimed.clear()
 check(main.run_save.restore() and GameManager.free_rerolls==1 and GameManager.bonus_moves==3 and GameManager.free_owned==["mobius"] and GameManager.tags_claimed==["piggy","moves"],"Tag state survives save and Continue")
 # Route UI: preview Tags for a new run and skip the opening batch.
 GameManager.state="menu"
 main.to_menu()
 await frames()
 main.get_node("Menu/Layout/Seed").text="4242"
 main.begin_run()
 await frames()
 var route: Control=main.route
 var expected: String=TagCatalog.for_round(4242,0)
 check(route.visible and route.skip_button.visible and route.skip_button.text.contains(TagCatalog.ITEMS[expected].name.trim_suffix(" Tag")),"New-run route previews the opening Tag")
 await capture("tags_route")
 await click(route.skip_button)
 check(GameManager.run_seed==4242 and GameManager.round_index==0 and GameManager.state=="shop" and GameManager.tags_claimed==[expected],"Skip button starts the seeded run and skips the opening batch")
 check(route.visible and route.target_index==1 and route.skip_button.visible,"Route moves on to the Big batch, which can be skipped too")
 await click(route.skip_button)
 check(GameManager.round_index==1 and route.target_index==2 and not route.skip_button.visible,"After skipping Small and Big the Boss has no Skip")
 await click(route.back_button)
 await frames()
 check(shop.get_node("Heading").text=="SKIPPED" and not shop.levels_button.visible and not shop.get_node("Actions/Reroll").visible,"Shop behind the route is shown as closed")
 await capture("tags_closed_shop")
 await click(shop.get_node("Actions/Continue"))
 await click(route.enter_button)
 check(GameManager.round_index==2 and GameManager.state=="playing","Playing on from a skipped shop starts the Boss")
 print("RESULT: %s tag/interest checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
