extends Node
var checks: int=0
var failures: int=0
var cfg: RunConfig=preload("res://resources/default_run.tres")
func check(ok: bool,message: String) -> void:
 checks+=1
 if ok: print("PASS: "+message)
 else:
  failures+=1
  push_error("FAIL: "+message)
func _ready() -> void:
 call_deferred("run_tests")
func frames() -> void:
 for i: int in range(3): await get_tree().process_frame
func fixture(rules: JokerManager, length: int) -> BoardModel:
 var model: BoardModel=BoardModel.new()
 model.setup(cfg,rules,73)
 for i: int in range(64): model.cells.append(CandyState.new(2))
 for i: int in range(24,24+length): model.cells[i].color=0
 model.cells[17].color=5
 model.locked_color=5
 model.cells[33].blocker=2
 model.cells[63].blocker=2
 return model
func group(length: int) -> Dictionary:
 var ids: Array[int]=[]
 for i: int in range(24,24+length): ids.append(i)
 return {"cells":ids,"length":length,"color":0,"axis":Vector2i.RIGHT,"shape":false,"diagonal":false}
func run_tests() -> void:
 var rules: JokerManager=JokerManager.new()
 add_child(rules)
 var model: BoardModel=BoardModel.new()
 model.setup(cfg,rules,402)
 var chances: Array[float]=model.spawn_chances()
 var expected: Array[float]=[0.30,0.24,0.18,0.13,0.09,0.06]
 check(chances==expected,"Base draw chances are 30/24/18/13/9/6 percent")
 var ordered: bool=true
 for i: int in range(1,6): ordered=ordered and cfg.candies[i].base_chips>cfg.candies[i-1].base_chips and chances[i]<chances[i-1]
 check(ordered,"Every higher-value candy has a lower base spawn chance")
 var counts: Array[int]=[0,0,0,0,0,0]
 for i: int in range(60000): counts[model.roll_color()]+=1
 var distribution_ok: bool=true
 for i: int in range(6): distribution_ok=distribution_ok and absf(counts[i]/60000.0-expected[i])<0.008
 check(distribution_ok,"60,000 seeded draws agree with configured rarity within 0.8 percentage points")
 var initial_counts: Array[int]=[0,0,0,0,0,0]
 for seed_value: int in range(80):
  model.rng.seed=seed_value+1
  model.fill_fresh()
  for cell: CandyState in model.cells: initial_counts[cell.color]+=1
 var initial_order: bool=true
 for i: int in range(1,6): initial_order=initial_order and initial_counts[i]<initial_counts[i-1]
 print("Initial board color counts: ",initial_counts)
 check(initial_order,"80 stabilized starting boards retain the common-to-rare frequency order")
 var supplies: Array[JokerData]=[]
 for item: JokerData in cfg.jokers:
  if item.category=="Supply": supplies.append(item)
 check(supplies.size()==6,"One Supply Joker exists for every candy type")
 for item: JokerData in supplies:
  rules.equipped.clear()
  rules.add(item)
  var adjusted: Array[float]=model.spawn_chances()
  var color: int=item.spawn_color
  check(is_equal_approx(adjusted[color],expected[color]*2/(1+expected[color])),"Normalized odds reflect "+item.display_name)
 rules.equipped.clear()
 rules.add(supplies[0])
 rules.add(supplies[5])
 chances=model.spawn_chances()
 check(is_equal_approx(chances[0],60.0/136.0) and is_equal_approx(chances[5],12.0/136.0),"Common and rare Supply Jokers stack without erasing other types")
 var twin: BoardModel=BoardModel.new()
 twin.setup(cfg,rules,55)
 model.setup(cfg,rules,55)
 var deterministic: bool=true
 for i: int in range(100): deterministic=deterministic and model.roll_color()==twin.roll_color()
 check(deterministic,"Weighted spawns remain reproducible from a seed")
 rules.equipped.clear()
 for length: int in [3,4,5]:
  model=fixture(rules,length)
  var effect: Dictionary=model.expand(group(length))
  check(17 in effect.cells and 33 in effect.cells and 63 not in effect.cells,"Match %s breaks adjacent locked color and blocker, without spreading" % length)
  check(effect.broken.size()==2 and effect.break_bonus==[10,25,50][length-3],"Match %s awards the correct per-tile breaking bonus" % length)
  var total: int=[140,260,240][length-3]
  check(effect.chips==total,"Match %s includes hidden candy values plus each bonus exactly once" % length)
  check(ScoreEngine.calculate(effect.chips,group(length),false,rules,0,false,false,64,0).total==total*(length-2),"Break rewards enter Candys before Mult")
  model.remove(effect.cells)
  check(33 in model.graves,"Destroyed blockers remain available for Necromancer")
 var blocker_image: Image=UIStyle.texture("ui_blocker").get_image()
 check(blocker_image.get_pixel(28,28).a==0,"Open Aseprite blocker frame leaves the candy center completely visible")
 var main: Control=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 main.get_node("Menu/Layout/Seed").text="73"
 main.start()
 GameManager.motion=false
 main.show_candy_guide()
 await frames()
 var guide: Control=main.get_node("CandyGuide")
 check(guide.visible and guide.rows.get_child_count()==6,"Candy Guide lists all six types with values and current odds")
 check(guide.close_button.get_global_rect().end.y<=710,"Candy Guide fits the logical canvas")
 await capture("v6_candy_guide")
 guide.close_button.pressed.emit()
 check(not guide.visible and not main.board.paused,"Closing the guide restores board input")
 await capture("v6_gameplay")
 GameManager.score=GameManager.current_round().quota
 GameManager.settle_round()
 GameManager.gummies=20
 GameManager.offers.assign([supplies[0],supplies[3],supplies[4],supplies[5]])
 GameManager.changed.emit()
 await frames()
 var shop: Control=main.get_node("Shop")
 check(not shop.get_node("Details").visible and not shop.get_node("Wallet").visible and not shop.get_node("Tip").visible,"Shop hides unselected descriptions and repeated cash/instructions")
 var lean: bool=true
 for column: Node in shop.get_node("Offers").get_children(): lean=lean and column.get_child_count()==2
 check(lean,"Each shop offer contains only the card and one price/action")
 await capture("v6_shop_clean")
 shop.card_buttons["supply_caramel"].pressed.emit()
 check(shop.get_node("Details").visible and shop.selected.id=="supply_caramel","Selecting a card reveals just its effect and transaction")
 shop.offer_buttons["supply_caramel"].pressed.emit()
 check(GameManager.jokers.has("supply_caramel") and GameManager.gummies==10,"Supply Joker buys and equips through the real shop")
 main.show_candy_guide()
 await frames()
 check(guide.rows.get_child(5).get_child(3).text=="11.3%","Guide immediately shows increased Caramel chance after purchase")
 guide.close_button.pressed.emit()
 GameManager.next_round()
 var board: GameBoard=main.get_node("Play/GameBoard")
 check(is_equal_approx(board.model.spawn_chances()[5],12.0/106.0),"Purchased Supply Joker applies to the next board")
 print("RESULT: %s rarity/break/shop checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 var folder: String=OS.get_environment("SUGAR_CAPTURE_DIR")
 if not folder.is_empty(): get_viewport().get_texture().get_image().save_png(folder+"/"+name+".png")
