extends Node

var failures: int = 0
var checks: int = 0
var cfg: RunConfig = preload("res://resources/default_run.tres")
var rules: JokerManager
var model: BoardModel

func check(value: bool, description: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("FAIL: " + description)
 else: print("PASS: ", description)

func equip(ids: Array[String]) -> void:
 rules.equipped.clear()
 for id: String in ids:
  for item: JokerData in cfg.jokers:
   if item.id == id: rules.add(item)

func fixture(ids: Array[int], color: int = 0) -> void:
 model.cells.clear()
 model.isotopes.clear()
 model.graves.clear()
 model.recycled.clear()
 model.locked_color = -1
 for i: int in range(64):
  var cell: CandyState = CandyState.new((i%8+(i/8)*2)%6)
  cell.blocker = 1
  cell.coating = 3 # Isolate the geometry fixture from surrounding colors.
  if i in ids:
   cell.blocker = 0
   cell.coating = 0
   cell.color = color
  model.cells.append(cell)

func group(ids: Array[int], length: int) -> Dictionary:
 return {"cells":ids,"color":0,"length":length,"diagonal":false,"shape":false,"axis":Vector2i.RIGHT}

func _ready() -> void:
 rules = JokerManager.new()
 add_child(rules)
 model = BoardModel.new()
 model.setup(cfg,rules,38)
 call_deferred("run_tests")

func run_tests() -> void:
 check(cfg.candies.size()==6 and cfg.jokers.size()==26 and cfg.rounds.size()==18,"All content resources load")
 fixture([0,1,2])
 check(model.matches().size()==1,"Ordinary horizontal match")
 fixture([0,8,16])
 check(model.matches().size()==1,"Ordinary vertical match")
 fixture([0,9,18])
 check(model.matches().is_empty(),"Diagonals invalid without Prism")
 equip(["kaleidoscope"])
 check(model.matches().size()==1 and model.matches()[0].diagonal,"Kaleidoscope enables diagonals")
 var diagonal: Dictionary = group([0,9,18],3)
 diagonal.diagonal = true
 check(ScoreEngine.calculate(30,diagonal,false,rules,0,false,false,64,0).total==45,"Diagonal grants 1.5x base chips")
 equip(["mobius"])
 fixture([6,7,0])
 check(model.matches().size()==1,"Mobius horizontal seam")
 fixture([48,56,0])
 check(model.matches().size()==1,"Mobius vertical seam")
 fixture([0,1,2,3,4,5,6,7])
 check(model.matches().size()==1 and model.matches()[0].cells.size()==8,"Full wrapping cycle deduplicates")
 equip(["labyrinth"])
 fixture([0,1,2])
 check(model.matches().is_empty(),"Labyrinth rejects three")
 fixture([0,1,2,3])
 check(model.matches().size()==1,"Labyrinth accepts four")
 check(ScoreEngine.calculate(40,group([0,1,2,3],4),false,rules,0,false,false,64,0).total==240,"Labyrinth triples four score")
 equip(["tsquare"])
 fixture([0,1,2,8,16])
 check(model.matches().size()==1 and model.matches()[0].length==5 and model.matches()[0].cells.size()==5,"L shape becomes five and center counted once")
 fixture([0,1,2,9,17])
 check(model.matches().size()==1 and model.matches()[0].length==5,"T shape becomes five")
 equip(["gravity"])
 fixture([0,1,2,3,7,15,23,31,63])
 var effect: Dictionary = model.expand(group([0,1,2,3],4))
 check(effect.cells.size()-effect.broken.size()==8 and 63 not in effect.cells,"Gravity attracts exactly four nearest same-color candies")
 equip(["paintball"])
 fixture([0,1,2,3,8,9,10,11])
 model.cells[8].color=1
 model.cells[9].color=2
 model.expand(group([0,1,2,3],4))
 check(model.cells[8].color==0 and model.cells[9].color==0,"Paintball recolors neighbors")
 equip(["sledgehammer"])
 fixture([0,1,2,3])
 model.cells[63].blocker=5
 effect=model.expand(group([0,1,2,3],4))
 check(63 in effect.cells,"Sledgehammer chooses strongest obstacle")
 equip(["ricochet"])
 fixture([0,1,2,3,4,5,6,7])
 effect=model.expand(group([0,1,2,3],4))
 check(effect.cells.size()-effect.broken.size()==8 and model.recycled.size()==4,"Ricochet clears row and recycles collateral")
 model.remove(effect.cells)
 model.refill()
 var coated_count: int = 0
 for cell: CandyState in model.cells:
  if cell.coating==1: coated_count+=1
 check(coated_count==4,"Ricochet caramel variants survive refill")
 equip(["nuclear"])
 fixture([18,19,20,21,22])
 effect=model.expand(group([18,19,20,21,22],5))
 check(9 in effect.cells and 27 in effect.cells and 18 in model.isotopes and not effect.isotope,"Nuclear 3x3 and persistent isotope, no immediate x4")
 check(ScoreEngine.calculate(30,group([18,19,20],3),true,rules,0,false,false,64,0).total==120,"Isotope multiplies future score by four")
 equip(["midas"])
 fixture([0,1,2,3,4,63])
 model.expand(group([0,1,2,3,4],5))
 check(model.cells[63].coating==2 and model.cells[0].chips(cfg)==80,"Midas gilds all matching color, including matched set")
 equip(["prism"])
 fixture([0,1,2,3,4])
 effect=model.expand(group([0,1,2,3,4],5))
 check(effect.wild==0,"Prism schedules wildcard spawn")
 model.fill_fresh()
 for color: int in range(6): model.cells[color].color=color
 model.cells[0].coating=3
 var wild: Array[Dictionary] = model.wild_groups(0,1)
 check(wild.size()==6,"Wild Prism triggers all six present colors")
 equip(["necro"])
 fixture([0,1,2,3,4])
 model.graves.append(63)
 model.expand(group([0,1,2,3,4],5))
 check(model.cells[63].coating==2 and model.cells[63].blocker==0 and model.graves.is_empty(),"Necromancer revives graves and live blockers as gold")
 equip(["addict"])
 check(ScoreEngine.calculate(30,group([0,1,2],3),false,rules,2,false,false,64,0).total==210,"Addict stacks +3 Mult per successful turn")
 equip(["roulette"])
 check(ScoreEngine.calculate(30,group([0,1,2],3),false,rules,0,true,false,64,0).total==60,"Roulette doubles poisoned score")
 equip(["broken"])
 var broken: Dictionary = ScoreEngine.calculate(30,group([0,1,2],3),false,rules,0,false,false,64,0)
 check(broken.total==30 and broken.chips==1 and broken.mult==30,"Broken Scale exchanges operands, same product")
 equip(["ouroboros"])
 check(ScoreEngine.calculate(30,group([0,1,2],3),false,rules,0,false,true,62,0).total==1860,"Ouroboros final-move population multiplier")
 equip([])
 fixture([0,1,2])
 model.locked_color=0
 check(model.matches().size()==1 and model.playable(0),"Inspector candies can be swapped and matched directly to break their locks")
 model.locked_color=-1
 model.cells[0].age=3
 model.cells[1].age=3
 model.age_candies([1])
 check(model.cells[0].blocker==1 and model.cells[1].blocker==0,"Heatwave converts aged stationary candy only")
 fixture([0,8,16,24,32,40,48,56])
 model.cells[24].blocker=2
 var anchor: CandyState=model.cells[24]
 model.remove([8,40])
 model.refill()
 check(model.cells[24]==anchor and model.cells.size()==64 and null not in model.cells,"Gravity preserves blocker anchors and fills all holes")
 # Initial boards must be stable and playable across combinations, seeds and curses.
 for build: Array in [[],["mobius"],["kaleidoscope"],["labyrinth"],["mobius","kaleidoscope","labyrinth","tsquare"]]:
  var ids: Array[String]=[]
  ids.assign(build)
  equip(ids)
  var valid: bool=true
  for seed_value: int in range(1,21):
   model.rng.seed=seed_value
   model.locked_color=-1
   model.fill_fresh()
   if model.legal_moves().is_empty(): model.reshuffle()
   valid = valid and model.matches().is_empty() and not model.legal_moves().is_empty()
  check(valid,"20 stable playable seeds for geometry build "+str(build))
 await integration()
 print("RESULT: %s checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)

func integration() -> void:
 var main: Control = preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await get_tree().process_frame
 await capture("title")
 main.get_node("Menu/Layout/Seed").text="38038"
 main.get_node("Menu/Layout/Play").pressed.emit()
 main.get_node("RoundMap").enter_button.pressed.emit()
 GameManager.motion=false
 var board: GameBoard=main.get_node("Play/GameBoard")
 check(GameManager.state=="playing" and board.tiles.size()==64,"Title starts a fully wired board")
 var legal: Array[Vector2i]=board.model.legal_moves()
 var before: int=GameManager.moves
 await board.attempt_swap(legal[0].x,legal[0].y)
 check(GameManager.moves==before-1 and GameManager.score>0 and not board.busy,"Real swap resolves, scores, consumes one move, unlocks input")
 check(board.model.matches().is_empty(),"Resolved board has no unprocessed matches")
 main.get_node("Play/Hint").pressed.emit()
 check(board.tiles.any(func(t: SugarTile) -> bool: return t.hinted),"Hint button highlights legal move")
 await capture("gameplay")
 # Force invalid swap on a stable board and check streak reset.
 var invalid: Vector2i=Vector2i(-1,-1)
 for i: int in range(63):
  if board.model.adjacent(i,i+1) and board.model.playable(i) and board.model.playable(i+1) and Vector2i(i,i+1) not in board.model.legal_moves():
   invalid=Vector2i(i,i+1)
   break
 if invalid.x>=0:
  before=GameManager.moves
  await board.attempt_swap(invalid.x,invalid.y)
  check(GameManager.moves==before-1 and GameManager.streak==0,"Failed swap consumes one move and resets streak")
 GameManager.score=GameManager.current_round().quota+123
 var wallet: int=GameManager.gummies
 GameManager.settle_round()
 check(GameManager.state=="shop" and GameManager.gummies==wallet+GameManager.round_reward()+mini(3,GameManager.moves/3),"Clear pays fixed cash and capped moves bonus, not overflow")
 check(GameManager.offers.size()==4,"Shop offers four unique unequipped Jokers")
 GameManager.gummies=30
 var offer: JokerData=GameManager.offers[0]
 wallet=GameManager.gummies
 check(GameManager.buy(offer) and GameManager.gummies==wallet-offer.price and GameManager.jokers.has(offer.id),"Shop purchase equips and charges once")
 check(not GameManager.buy(offer),"Repeated purchase rejected")
 await get_tree().process_frame
 await capture("shop")
 wallet=GameManager.gummies
 GameManager.sell(offer)
 check(GameManager.gummies==wallet+offer.price/2 and not GameManager.jokers.has(offer.id),"Selling returns half price")
 GameManager.gummies=0
 check(not GameManager.buy(GameManager.offers[0]),"Insufficient funds rejected")
 GameManager.next_round()
 check(GameManager.round_index==1 and GameManager.moves==10 and GameManager.score==0,"Next batch resets round state")
 GameManager.jokers.equipped.assign([cfg.jokers[13]])
 GameManager.start_round()
 GameManager.score=800
 GameManager.poison_cleared=false
 GameManager.moves=0
 GameManager.finish_move()
 check(GameManager.score==400 and GameManager.state=="over","Uncleared poison halves score before quota evaluation")
 await capture("game_over")
 GameManager.start_run(38038)
 for i: int in range(cfg.rounds.size()):
  GameManager.score=GameManager.current_round().quota
  GameManager.settle_round()
  if i<cfg.rounds.size()-1: GameManager.next_round()
 check(GameManager.round_index==cfg.rounds.size()-1 and GameManager.state=="over","Eighteen-batch campaign reaches victory")
 await capture("victory")
 main.queue_free()
 await get_tree().process_frame

func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var target: String=OS.get_environment("SUGAR_CAPTURE_DIR")
 if target.is_empty(): return
 get_viewport().get_texture().get_image().save_png(target+"/"+name+".png")
