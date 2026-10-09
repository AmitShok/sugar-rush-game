extends Node
var failures: int=0
var checks: int=0
var cfg: RunConfig=preload("res://resources/default_run.tres")
var rules: JokerManager
var model: BoardModel
func check(ok: bool, message: String) -> void:
 checks+=1
 if ok: print("PASS: "+message)
 else:
  failures+=1
  push_error(message)
func fixture(equipped: Array[String]) -> void:
 rules.equipped.clear()
 for item: JokerData in cfg.jokers:
  if item.id in equipped: rules.add(item)
 model.cells.clear()
 model.isotopes.clear()
 for i: int in range(64): model.cells.append(CandyState.new(1))
 for i: int in [26,27,28,0,63]: model.cells[i].color=0
func group(ids: Array[int]) -> Dictionary:
 return {"cells":ids,"color":0,"length":ids.size(),"diagonal":false,"shape":false,"axis":Vector2i.RIGHT}
func _ready() -> void:
 rules=JokerManager.new()
 add_child(rules)
 model=BoardModel.new()
 model.setup(cfg,rules,42)
 fixture(["pop_rock"])
 var effect: Dictionary=model.expand(group([26,27,28]))
 check(effect.cells.size()==9 and 18 in effect.cells and 36 in effect.cells,"Blast covers 3x3 centered on middle candy")
 check(model.isotopes.is_empty(),"Pop Rock creates no nuclear isotope")
 effect=model.expand(group([0,1,2]))
 check(effect.cells.size()==6,"Blast clips at board edge")
 fixture(["sweet_tooth"])
 effect=model.expand(group([26,27,28]))
 check(effect.cells.size()==5 and 0 in effect.cells and 63 in effect.cells,"Sweet Tooth finds two extra matching candies")
 fixture(["golden_trio"])
 model.cells[27].blocker=2
 effect=model.expand(group([26,27,28]))
 check(effect.chips==250 and effect.broken==[27],"Gold trio scores 240 plus trapped-candy break bonus")
 fixture(["three_scoops"])
 check(model.expand(group([26,27,28])).chips==60,"Thirty bonus Candys added to three berries before Mult")
 fixture(["pop_rock","sweet_tooth","golden_trio","three_scoops"])
 effect=model.expand(group([26,27,28]))
 check(effect.effects.size()==4 and effect.cells.size()==11 and effect.chips==374,"All four effects stack with unique candy scoring")
 var reverse_ids: Array[int]=[28,27,26]
 check(model.expand(group(reverse_ids)).cells.size()==11,"Reversed line retains its blast center")
 var synthetic: Dictionary=group([26,27,28])
 synthetic.synthetic=true
 check(model.expand(synthetic).effects.is_empty(),"Wild swap mini-clears do not impersonate real matches of three")
 for raw_ids: Array in [[26,27,28,29],[26,27,28,29,30]]:
  var ids: Array[int]=[]
  ids.assign(raw_ids)
  effect=model.expand(group(ids))
  check(effect.effects==(["line"] if ids.size()==4 else ["color"]),"Larger matches retain their default special")
 fixture(["pop_rock"])
 model.cells[18].blocker=1
 effect=model.expand(group([26,27,28]))
 check(18 in effect.broken and effect.contributions[18]==24,"Explosion breaks locks and awards the break bonus")
 print("RESULT: %s match-three checks, %s failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
