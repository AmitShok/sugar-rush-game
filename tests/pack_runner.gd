extends "res://tests/upgrade_runner.gd"
# Booster packs: rolls, prices, opening, every pack kind, rare cards, Pack Tag, shop page, modal and saves.
func open_kind(kind: String, jumbo: bool = false) -> bool:
 GameManager.opened_pack = {}
 GameManager.pack_offers.assign([{"kind":kind,"jumbo":jumbo,"free":false}])
 return GameManager.open_pack(0)
func run_tests() -> void:
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 shop=main.get_node("Shop")
 var panel: Control=main.pack_panel
 # Rolls.
 var counts: Dictionary={}
 var jumbo_count: int=0
 for i: int in range(5000):
  var pack: Dictionary=PackCatalog.roll([3,i])
  counts[pack.kind]=counts.get(pack.kind,0)+1
  if pack.jumbo: jumbo_count+=1
  if pack.kind=="rush" and pack.jumbo: counts["bad"]=1
 check(counts.size()==5 and not counts.has("bad"),"All five pack kinds roll; Sugar Rush packs are never Jumbo")
 check(absf(counts.rush/5000.0-0.10)<0.02 and absf(counts.joker/5000.0-0.30)<0.03,"Pack odds follow the weights (rare pack about 10%)")
 check(PackCatalog.roll([1,2])==PackCatalog.roll([1,2]),"Pack rolls are deterministic")
 check(PackCatalog.price({"kind":"candy","jumbo":false})==3 and PackCatalog.price({"kind":"joker","jumbo":true})==6 and PackCatalog.price({"kind":"recipe","jumbo":true,"free":true})==0,"Pack prices, Jumbo prices and free packs")
 # Shop stock.
 GameManager.start_run(7300)
 GameManager.motion=false
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 check(GameManager.pack_offers.size()==2,"Each shop stocks two packs")
 var stock: Array=GameManager.pack_offers.duplicate(true)
 GameManager.gummies=50
 GameManager.reroll()
 check(GameManager.pack_offers==stock,"Rerolls do not change packs")
 # Opening and taking cards.
 GameManager.gummies=20
 check(open_kind("recipe") and GameManager.gummies==16 and GameManager.pack_offers.is_empty(),"Opening pays the price and uses up the pack slot")
 check(GameManager.opened_pack.choices.size()==3 and GameManager.opened_pack.picks==1,"Recipe Pack shows 3 recipes, keep 1")
 var recipe_id: String=String(GameManager.opened_pack.choices[0].id)
 var before: int=GameManager.recipe_level(recipe_id)
 check(GameManager.take_pack_card(0) and GameManager.recipe_level(recipe_id)==before+1 and GameManager.opened_pack.is_empty(),"Taking a recipe levels it up and closes the pack")
 var diag_ok: bool=true
 for i: int in range(20):
  open_kind("recipe",true)
  for choice: Dictionary in GameManager.opened_pack.choices: diag_ok=diag_ok and choice.id!="diagonal"
  GameManager.gummies=50
 check(diag_ok,"Diagonal only appears in Recipe Packs with Kaleidoscope")
 check(open_kind("recipe",true) and GameManager.opened_pack.choices.size()==4 and GameManager.opened_pack.picks==2,"Jumbo Recipe Pack: 4 non-Diagonal choices without Kaleidoscope, keep 2")
 GameManager.take_pack_card(0)
 check(not GameManager.opened_pack.is_empty() and GameManager.opened_pack.picks==1 and GameManager.opened_pack.choices.size()==3,"After the first of two picks the pack stays open")
 GameManager.skip_pack()
 check(GameManager.opened_pack.is_empty(),"Skip closes the pack")
 GameManager.gummies=50
 open_kind("candy")
 var color: int=int(GameManager.opened_pack.choices[1].id)
 var value: int=GameManager.candy_value(color)
 GameManager.take_pack_card(1)
 check(GameManager.candy_value(color)==value+GameManager.upgrade_gain(color),"Candy Pack upgrades the chosen candy type")
 GameManager.jokers.clear_all()
 open_kind("joker",true)
 var jokers_ok: bool=GameManager.opened_pack.choices.size()==4
 for choice: Dictionary in GameManager.opened_pack.choices: jokers_ok=jokers_ok and GameManager.joker_by_id(String(choice.id))!=null and choice.has("edition")
 check(jokers_ok,"Jumbo Joker Pack shows four Jokers, each with an edition roll")
 var joker_choice: Dictionary=GameManager.opened_pack.choices[2]
 GameManager.take_pack_card(2)
 check(GameManager.jokers.has(String(joker_choice.id)) and GameManager.jokers.edition(String(joker_choice.id))==String(joker_choice.edition),"Taking a Joker equips it with its edition")
 for item: JokerData in GameManager.config.jokers:
  if GameManager.jokers.can_add(item): GameManager.jokers.add(item)
 check(GameManager.jokers.equipped.size()==5,"Fixture fills all five slots")
 open_kind("joker")
 check(GameManager.pack_block_reason(GameManager.opened_pack.choices[0])!="" and not GameManager.take_pack_card(0),"Joker cards cannot be taken with full slots")
 GameManager.skip_pack()
 GameManager.consumables.assign(["sugar_shaker","sugar_shaker"])
 open_kind("treat")
 check(not GameManager.take_pack_card(0),"Treat cards need a free item slot")
 GameManager.consumables.clear()
 GameManager.take_pack_card(0)
 check(GameManager.consumables.size()==1,"Treat Pack gives a consumable")
 # Rare cards.
 GameManager.jokers.clear_all()
 GameManager.jokers.add(GameManager.config.jokers[0])
 GameManager.jokers.add(GameManager.config.jokers[1])
 GameManager.apply_rush("glitter")
 var shiny: int=0
 for item: JokerData in GameManager.jokers.equipped:
  if not GameManager.jokers.edition(item.id).is_empty(): shiny+=1
 check(shiny==1,"Glitter gives one owned Joker an edition")
 var levels: Dictionary=GameManager.recipe_levels.duplicate()
 GameManager.apply_rush("cookbook_blast")
 var all_up: bool=true
 for id: String in RecipeCatalog.ORDER: all_up=all_up and GameManager.recipe_level(id)==int(levels.get(id,1))+1
 check(all_up,"Cookbook Blast levels every recipe")
 GameManager.gummies=4
 GameManager.apply_rush("big_spoon")
 check(GameManager.jokers.capacity==6 and GameManager.gummies==0,"Big Spoon adds a Joker slot and costs up to $10")
 GameManager.apply_rush("big_spoon")
 check(GameManager.jokers.capacity==6,"Joker slots are capped at 6")
 GameManager.apply_rush("meltdown")
 check(GameManager.jokers.equipped.size()==1 and GameManager.jokers.edition(GameManager.jokers.equipped[0].id)=="poly","Meltdown destroys one Joker and makes another Polychrome")
 GameManager.gummies=30
 GameManager.apply_rush("golden_batch")
 check(GameManager.gummies==50 and GameManager.interest()==2,"Golden Batch pays $20 and halves the interest cap")
 GameManager.jokers.clear_all()
 open_kind("rush")
 var rush_ok: bool=GameManager.opened_pack.choices.size()==2
 for choice: Dictionary in GameManager.opened_pack.choices: rush_ok=rush_ok and choice.id not in ["meltdown","glitter","big_spoon"]
 check(rush_ok,"Rare cards that cannot work are not offered (no Jokers, slots maxed)")
 GameManager.skip_pack()
 # Pack Tag.
 GameManager.free_packs=1
 GameManager.round_index=0
 GameManager.next_round()
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 check(PackCatalog.price(GameManager.pack_offers[0])==0 and (GameManager.pack_offers[0].jumbo or GameManager.pack_offers[0].kind=="rush") and GameManager.free_packs==0,"Pack Tag makes the next shop's first pack a free Jumbo")
 check(TagCatalog.ITEMS.has("pack"),"Pack Tag is a skip reward")
 # Shop page and modal, physically.
 GameManager.gummies=40
 GameManager.jokers.capacity=5
 GameManager.changed.emit()
 await frames()
 await click(shop.pack_tab)
 check(shop.page=="packs" and shop.pack_buttons.size()==2 and shop.pack_row.visible and not shop.get_node("Offers").visible,"Packs tab shows two packs with Open buttons")
 check(shop.pack_row.get_global_rect().end.x<=1152 and shop.pack_row.get_global_rect().end.y<=shop.get_node("Details").get_global_rect().position.y+2,"Pack page fits above the details panel")
 await capture("packs_shop")
 await click(shop.pack_buttons[0])
 await frames()
 check(panel.visible and panel.take_buttons.size()==GameManager.opened_pack.choices.size(),"Opening shows the pack modal with one Take per card")
 await capture("pack_open")
 var picks: int=int(GameManager.opened_pack.picks)
 await click(panel.take_buttons[0])
 await frames()
 check((picks==1 and not panel.visible) or (picks==2 and panel.visible),"Taking the last pick closes the modal")
 if panel.visible: await click(panel.skip_button)
 check(not panel.visible and GameManager.opened_pack.is_empty(),"Skip button closes the modal")
 # Saves, including an open pack and extra slots.
 GameManager.gummies=40
 open_kind("candy",true)
 GameManager.jokers.capacity=6
 GameManager.interest_halved=true
 GameManager.free_packs=1
 var open_state: Dictionary=GameManager.opened_pack.duplicate(true)
 main.run_save.checkpoint()
 GameManager.opened_pack={}
 GameManager.jokers.capacity=5
 GameManager.interest_halved=false
 GameManager.free_packs=0
 check(main.run_save.restore() and GameManager.opened_pack==open_state and GameManager.jokers.capacity==6 and GameManager.interest_halved and GameManager.free_packs==1,"Open pack, Joker slots, Golden Batch and Pack Tag survive save and Continue")
 GameManager.changed.emit()
 await frames()
 check(panel.visible,"A restored open pack shows its modal again")
 GameManager.start_run(7301)
 check(GameManager.opened_pack.is_empty() and GameManager.jokers.capacity==5 and not GameManager.interest_halved and GameManager.pack_offers.is_empty(),"New run resets packs, slots and Golden Batch")
 print("RESULT: %s booster pack checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
