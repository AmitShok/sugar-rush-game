extends "res://tests/consumable_runner.gd"
func run_tests() -> void:
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 var saver: Node=main.run_save
 check(not saver.has_save(),"Fresh install has no Continue save")
 main.start()
 GameManager.motion=false
 await frames()
 check(saver.has_save(),"Starting a run creates a disk checkpoint")
 var board: GameBoard=main.board
 GameManager.gummies=55
 GameManager.consumables.assign(["candy_hammer","extra_serving"])
 GameManager.candy_levels[0]=3
 GameManager.candy_bonuses[0]=15
 GameManager.jokers.equipped.append(GameManager.config.jokers[0])
 board.model.cells[0].coating=2
 board.model.cells[0].age=3
 board.model.isotopes.assign([0])
 board.model.graves.assign([17])
 board.model.recycled.append(CandyState.new(4))
 saver.checkpoint()
 var saved: Dictionary=saver.read_save()
 var expected_roll: int=board.model.rng.randi()
 GameManager.gummies=0
 board.model.cells[0].coating=0
 check(saver.restore(),"Disk save restores successfully")
 check(saver.snapshot()==saved,"Every gameplay and board field round trips exactly")
 check(board.model.rng.randi()==expected_roll,"Board random sequence continues exactly")
 saver.restore()
 board.busy=true
 GameManager.score=999
 saver.checkpoint()
 check(saver.read_save()==saved,"Mid-cascade state cannot overwrite stable checkpoint")
 board.busy=false
 saver.restore()
 main.to_menu()
 check(not main.get_node("Menu/Layout/Continue").disabled,"Title offers Continue after leaving a run")
 await click(main.get_node("Menu/Layout/Continue"))
 check(GameManager.state=="playing" and main.get_node("Play").visible,"Continue button restores gameplay")
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 GameManager.gummies=100
 GameManager.consumables.clear()
 await frames()
 check(GameManager.consumable_offers.size()==2 and GameManager.consumable_offers[0]!=GameManager.consumable_offers[1],"Shop stocks exactly two random distinct cards")
 main.open_items()
 await frames()
 await capture("random_consumable_shop")
 var id: String=GameManager.consumable_offers[0]
 await click(main.item_panel.buttons[id])
 check(GameManager.consumable_offers.size()==1 and id not in main.item_panel.buttons,"Buying removes the offer from the shop")
 GameManager.discard_consumable(0)
 check(not GameManager.buy_consumable(id),"Discarding cannot replenish a purchased offer")
 check(GameManager.buy_consumable(GameManager.consumable_offers[0]) and GameManager.consumable_offers.is_empty(),"Only two purchases are available per refresh")
 GameManager.discard_consumable(0)
 var cash: int=GameManager.gummies
 var cost: int=GameManager.reroll_cost
 await click(main.item_panel.refresh_button)
 check(GameManager.consumable_offers.size()==2 and GameManager.gummies==cash-cost and GameManager.reroll_cost==cost+2,"Paid refresh replaces stock and raises the shared price")
 saver.checkpoint()
 saved=saver.read_save()
 GameManager.roll_offers()
 check(saver.restore() and saver.snapshot()==saved,"Shop save retains stock, cash, prices and purchased slots")
 main.close_items()
 main.to_menu()
 await frames()
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(OS.get_environment("SUGAR_CAPTURE_DIR")+"/continue_menu.png")
 check(main.get_node("Menu/Layout").get_global_rect().end.y<=720,"Continue and New Run menu fits the canvas")
 main.start()
 await frames()
 check(GameManager.round_index==0 and GameManager.consumables.is_empty() and GameManager.gummies==4,"New Run replaces the saved run with a fresh start")
 GameManager.state="over"
 saver.checkpoint()
 check(not saver.has_save(),"Completed or lost runs remove Continue save")
 var file: FileAccess=FileAccess.open(saver.path,FileAccess.WRITE)
 file.store_string("broken save")
 file.close()
 check(not saver.restore(),"Corrupt save is rejected safely")
 DirAccess.remove_absolute(saver.path)
 print("RESULT: %s save/stock checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
