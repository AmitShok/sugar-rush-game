extends "res://tests/upgrade_runner.gd"
# Special candies made by the Striper / Wrapper / Bomb Maker Jokers, their chains and swap combos.
var cfg: RunConfig = preload("res://resources/default_run.tres")
var rules: JokerManager
var model: BoardModel
func equip(ids: Array[String]) -> void:
 rules.equipped.clear()
 for id: String in ids:
  for item: JokerData in cfg.jokers:
   if item.id == id: rules.equipped.append(item)
func fresh() -> void:
 # Pattern with no matches: rows step by 1, columns by 2 (mod 6).
 model.cells.clear()
 model.isotopes.clear()
 model.graves.clear()
 model.locked_color = -1
 for i: int in range(64): model.cells.append(CandyState.new((i%8+2*(i/8))%6))
func line(ids: Array, color: int = 0, axis: Vector2i = Vector2i.RIGHT, pivot: int = -1) -> Dictionary:
 var cells: Array[int] = []
 for i: int in ids:
  cells.append(i)
  model.cells[i].color = color
 var g: Dictionary = {"cells":cells,"color":color,"length":cells.size(),"diagonal":false,"shape":false,"axis":axis}
 if pivot >= 0: g["pivot"] = pivot
 return g
func run_tests() -> void:
 rules = JokerManager.new()
 model = BoardModel.new()
 model.setup(cfg,rules,99)
 model.candy_bonuses.resize(6)
 model.candy_bonuses.fill(0)
 check(cfg.jokers.size()==32,"Three special-maker Jokers join the pool")
 for id: String in ["striper","wrapper","bomb_maker"]:
  var found: bool = false
  for item: JokerData in cfg.jokers:
   if item.id == id: found = item.category == "Special" and item.icon != null and item.price > 0
  check(found,"%s is a priced Special Joker with card art" % id)
 # Creation rules.
 fresh()
 equip([])
 var e: Dictionary = model.expand(line([0,1,2,3],0,Vector2i.RIGHT,2))
 check(e.spawn.is_empty() and e.cells.size()==4 and e.effects.is_empty(),"Without Jokers a line of 4 makes nothing and clears only itself")
 equip(["striper"])
 fresh()
 e = model.expand(line([0,1,2,3],0,Vector2i.RIGHT,2))
 check(e.spawn.get("special")==CandyState.STRIPE_V and e.spawn.get("index")==2,"Striper: horizontal 4 leaves a column-striped candy at the swapped cell")
 fresh()
 e = model.expand(line([0,8,16,24],0,Vector2i.DOWN,16))
 check(e.spawn.get("special")==CandyState.STRIPE_H,"Striper: vertical 4 leaves a row-striped candy")
 fresh()
 e = model.expand(line([0,1,2,3,4],0))
 check(e.spawn.get("special")==CandyState.STRIPE_V and e.spawn.get("index")==2,"Line of 5 falls back to Striped without Bomb Maker, at the middle cell")
 equip(["striper","bomb_maker"])
 fresh()
 e = model.expand(line([0,1,2,3,4],0))
 check(e.spawn.get("special")==CandyState.BOMB,"Bomb Maker: line of 5 leaves a Color Bomb")
 equip(["wrapper","striper"])
 fresh()
 var shape: Dictionary = line([0,1,2,8,16],0)
 shape.shape = true
 shape.length = 3
 e = model.expand(shape)
 check(e.spawn.get("special")==CandyState.WRAPPED,"Wrapper: L/T match leaves a Wrapped candy")
 equip(["three_scoops","striper"])
 fresh()
 var wild_group: Dictionary = line([0,1,2,3],0)
 wild_group.synthetic = true
 check(model.expand(wild_group).spawn.is_empty(),"Synthetic clears never make specials")
 # Detonation and chains.
 equip([])
 fresh()
 model.cells[1].special = CandyState.STRIPE_H
 e = model.expand(line([0,1,2],0))
 check(e.cells.size()==8 and 1 in e.fired,"Matched row-striped candy clears its whole row")
 fresh()
 model.cells[1].special = CandyState.STRIPE_H
 model.cells[5].special = CandyState.WRAPPED
 e = model.expand(line([0,1,2],0))
 check(e.cells.size()==8+3 and 5 in e.fired and 12 in e.cells and 13 in e.cells,"Blast chains into a Wrapped candy and its 3x3")
 fresh()
 model.cells[10].special = CandyState.STRIPE_V
 e = model.expand(line([9,10,11],0))
 check(e.cells.size()==10 and 58 in e.cells,"Column-striped candy clears its column")
 # Color Bomb rules.
 fresh()
 model.cells[0].special = CandyState.BOMB
 model.cells[1].color = 0
 model.cells[2].color = 0
 check(model.matches().is_empty(),"Color Bombs never match by color")
 check(model.is_special_swap(0,8) and Vector2i(0,1) in model.legal_moves(),"Any swap with a Color Bomb is legal")
 fresh()
 model.cells[0].special = CandyState.BOMB
 var target: int = model.cells[1].color
 var expected: int = 0
 for c: CandyState in model.cells:
  if c.color == target and c.special == CandyState.NONE: expected += 1
 model.swap(0,1)
 var groups: Array[Dictionary] = model.special_swap_groups(0,1)
 check(groups.size()==1 and groups[0].cells.size()==expected+1 and groups[0].color==target,"Bomb + candy clears every candy of that type")
 check(groups[0].synthetic and groups[0].special_swap and RecipeCatalog.classify(groups[0])=="quint","Combos are synthetic and score as Quint")
 # Two-special combos.
 fresh()
 model.cells[27].special = CandyState.STRIPE_H
 model.cells[28].special = CandyState.STRIPE_V
 check(model.is_special_swap(27,28) and Vector2i(27,28) in model.legal_moves(),"Two specials can always be swapped")
 model.swap(27,28)
 groups = model.special_swap_groups(27,28)
 check(groups[0].cells.size()==15,"Striped + Striped clears a full cross")
 check(model.cells[27].special==CandyState.NONE and model.cells[28].special==CandyState.NONE,"Combo consumes both specials")
 fresh()
 model.cells[27].special = CandyState.WRAPPED
 model.cells[28].special = CandyState.STRIPE_H
 model.swap(27,28)
 check(model.special_swap_groups(27,28)[0].cells.size()==3*8+3*8-9,"Striped + Wrapped clears three rows and three columns")
 fresh()
 model.cells[27].special = CandyState.WRAPPED
 model.cells[28].special = CandyState.WRAPPED
 model.swap(27,28)
 check(model.special_swap_groups(27,28)[0].cells.size()==25,"Wrapped + Wrapped blasts 5x5")
 fresh()
 model.cells[27].special = CandyState.BOMB
 model.cells[28].special = CandyState.BOMB
 model.swap(27,28)
 check(model.special_swap_groups(27,28)[0].cells.size()==64,"Two Color Bombs clear the whole board")
 fresh()
 model.cells[27].special = CandyState.BOMB
 model.cells[28].special = CandyState.STRIPE_H
 var striped_color: int = model.cells[28].color
 model.swap(27,28)
 groups = model.special_swap_groups(27,28)
 var converted: bool = true
 for i: int in range(64):
  if model.cells[i].color == striped_color and i != 27 and model.cells[i].special not in [CandyState.STRIPE_H,CandyState.STRIPE_V]: converted = false
 e = model.expand(groups[0])
 check(converted and e.fired.size() >= 10 and e.cells.size() > 40,"Bomb + Striped turns that type striped and fires them all")
 equip(["gravity","midas"])
 fresh()
 model.cells[27].special = CandyState.WRAPPED
 model.cells[28].special = CandyState.WRAPPED
 model.swap(27,28)
 check(model.expand(model.special_swap_groups(27,28)[0]).effects.is_empty(),"Combos do not trigger 4+/5+ Jokers")
 # Scoring: a striped row adds every cleared candy before Mult.
 equip([])
 fresh()
 model.cells[1].special = CandyState.STRIPE_H
 var row_group: Dictionary = line([0,1,2],0)
 var row_value: int = 0
 for i: int in range(8): row_value += model.cells[i].chips(cfg)
 e = model.expand(row_group)
 check(int(e.chips)==row_value,"Every candy in a striped blast adds its Candys")
 var scored: Dictionary = ScoreEngine.calculate(e.chips,row_group,false,rules,0,false,false,64,0)
 check(e.special_mult==4 and scored.total==row_value*(1+4),"A fired Striped candy adds +4 Mult to its match")
 fresh()
 model.cells[1].special = CandyState.WRAPPED
 model.cells[2].special = CandyState.BOMB
 e = model.expand(line([0,1,3],0))
 check(e.special_mult==6+10,"Wrapped adds +6 and a blasted Color Bomb +10 Mult")
 fresh()
 model.cells[27].special = CandyState.WRAPPED
 model.cells[28].special = CandyState.WRAPPED
 model.swap(27,28)
 var combo: Dictionary = model.special_swap_groups(27,28)[0]
 e = model.expand(combo)
 check(combo.combo_x==3.0 and ScoreEngine.calculate(e.chips,combo,false,rules,0,false,false,64,0).total==(e.chips+30)*3*3,"Special combos triple the Quint recipe Mult")
 fresh()
 model.cells[27].special = CandyState.BOMB
 model.cells[28].special = CandyState.BOMB
 model.swap(27,28)
 check(model.special_swap_groups(27,28)[0].combo_x==6.0,"Two Color Bombs give x6 Mult")
 # Saves and tiles.
 main=preload("res://scenes/MainGame.tscn").instantiate()
 add_child(main)
 await frames()
 GameManager.start_run(777)
 GameManager.motion=false
 var board: GameBoard=main.board
 board.model.cells[5].special=CandyState.WRAPPED
 board.model.cells[6].special=CandyState.BOMB
 var saver: Node=main.run_save
 saver.checkpoint()
 board.model.cells[5].special=CandyState.NONE
 board.model.cells[6].special=CandyState.NONE
 check(saver.restore() and board.model.cells[5].special==CandyState.WRAPPED and board.model.cells[6].special==CandyState.BOMB,"Specials survive save and Continue")
 var old_cells: Array[CandyState]=saver.unpack_cells([[2,0,0,0]])
 check(old_cells[0].special==CandyState.NONE,"Older four-field saves load as plain candies")
 board.sync_tiles(false)
 await frames()
 check(board.tiles[6].sprite.texture==UIStyle.texture("candy_bomb") and board.tiles[6].tooltip_text.begins_with("Color Bomb"),"Bomb tile shows bomb art and explains itself")
 check(board.tiles[5].tooltip_text.contains("Wrapped"),"Wrapped tile tooltip names the special")
 # Live board: making a Striped candy through the real resolver.
 for item: JokerData in cfg.jokers:
  if item.id == "striper": GameManager.jokers.equipped.assign([item])
 for i: int in range(64):
  board.model.cells[i]=CandyState.new((i%8+2*(i/8))%6)
 for i: int in [56,57,58,59]: board.model.cells[i].color=0
 board.sync_tiles(false)
 var group: Dictionary={"cells":[56,57,58,59],"color":0,"length":4,"diagonal":false,"shape":false,"axis":Vector2i.RIGHT,"pivot":58}
 var before: int=GameManager.score
 await board.resolve([group])
 var spawned: bool=false
 for child: Node in board.get_node("Juice").get_children():
  if child is Label and child.text=="STRIPED!": spawned=true
 check(GameManager.score>before and spawned,"Live resolver awards the match and announces the Striped candy")
 board.model.cells[58].special=CandyState.STRIPE_V
 board.model.cells[20].special=CandyState.WRAPPED
 board.model.cells[21].special=CandyState.BOMB
 board.sync_tiles(false)
 await frames()
 await capture("special_board")
 print("RESULT: %s special candy checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
