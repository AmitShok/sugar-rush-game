class_name BoardModel
extends RefCounted
var width: int = 8
var height: int = 8
var cells: Array[CandyState] = []
var isotopes: Array[int] = []
var graves: Array[int] = []
var recycled: Array[CandyState] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var rules: JokerManager
var config: RunConfig
var locked_color: int = -1
func setup(run_config: RunConfig, joker_rules: JokerManager, seed_value: int) -> void:
 config = run_config
 rules = joker_rules
 rng.seed = seed_value
func spawn_weights() -> Array[float]:
 var weights: Array[float] = []
 for color: int in range(config.candies.size()):
  var weight: float = maxf(0.001,config.candies[color].spawn_weight)
  for item: JokerData in rules.equipped:
   if item.spawn_color == color: weight *= maxf(0.01,item.spawn_multiplier)
  weights.append(weight)
 return weights
func spawn_chances() -> Array[float]:
 var weights: Array[float] = spawn_weights()
 var total: float = 0
 for weight: float in weights: total += weight
 for i: int in range(weights.size()): weights[i] /= total
 return weights
func roll_color() -> int:
 var weights: Array[float] = spawn_weights()
 var total: float = 0
 for weight: float in weights: total += weight
 var roll: float = rng.randf()*total
 for i: int in range(weights.size()):
  roll -= weights[i]
  if roll < 0: return i
 return weights.size()-1
func is_locked_tile(i: int) -> bool:
 return cells[i] != null and (cells[i].blocker > 0 or cells[i].color == locked_color)
func xy(i: int) -> Vector2i:
 return Vector2i(i % width, i / width)
func index(p: Vector2i) -> int:
 return p.y * width + p.x
func inside(p: Vector2i) -> bool:
 return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height
func playable(i: int) -> bool:
 return i >= 0 and i < cells.size() and cells[i] != null and cells[i].blocker == 0
func matchable(i: int) -> bool:
 return i >= 0 and i < cells.size() and cells[i] != null and cells[i].coating != 3
func same(i: int, color: int) -> bool:
 return matchable(i) and cells[i].color == color
func fill_fresh() -> void:
 cells.clear()
 isotopes.clear()
 graves.clear()
 recycled.clear()
 for i: int in range(width * height): cells.append(CandyState.new(roll_color()))
 stabilize()
func stabilize() -> void:
 for attempt: int in range(200):
  var found: Array[Dictionary] = matches()
  if found.is_empty(): return
  for group: Dictionary in found:
   for i: int in group.cells: cells[i].color = roll_color()
func matches() -> Array[Dictionary]:
 var lines: Array[Dictionary] = []
 var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]
 if rules.has("kaleidoscope"): directions.append_array([Vector2i(1,1),Vector2i(-1,1)])
 var seen: Dictionary = {}
 for direction: Vector2i in directions:
  for start: int in range(cells.size()):
   if not matchable(start): continue
   var color: int = cells[start].color
   var prior: Vector2i = xy(start)-direction
   if rules.has("mobius"): prior = Vector2i(posmod(prior.x,width),posmod(prior.y,height))
   # Full cyclic lines have no distinct start; canonical dedup handles them.
   if inside(prior) and same(index(prior),color):
    var full_cycle: bool = true
    var probe: Vector2i = xy(start)
    for k: int in range(maxi(width,height)):
     if not inside(probe) or not same(index(probe),color):
      full_cycle = false
      break
     probe += direction
     if rules.has("mobius"): probe = Vector2i(posmod(probe.x,width),posmod(probe.y,height))
    if not full_cycle: continue
   var run: Array[int] = []
   var p: Vector2i = xy(start)
   while inside(p) and same(index(p),color) and index(p) not in run:
    run.append(index(p))
    p += direction
    if rules.has("mobius"): p = Vector2i(posmod(p.x,width),posmod(p.y,height))
   if run.size() < 3: continue
   var sorted: Array[int] = run.duplicate()
   sorted.sort()
   var key: String = str(sorted)
   if seen.has(key): continue
   seen[key] = true
   lines.append({"cells":run,"color":color,"length":run.size(),"diagonal":direction.x != 0 and direction.y != 0,"shape":false,"axis":direction})
 # Merge intersecting lines, counting each candy once.
 var merged: Array[Dictionary] = []
 while not lines.is_empty():
  var group: Dictionary = lines.pop_back()
  var again: bool = true
  while again:
   again = false
   for j: int in range(lines.size()-1,-1,-1):
    var other: Dictionary = lines[j]
    var overlap: bool = false
    for cell: int in other.cells:
     if cell in group.cells: overlap = true
    if not overlap: continue
    group.shape = true
    group.diagonal = group.diagonal or other.diagonal
    group.length = maxi(group.length,other.length)
    for cell: int in other.cells:
     if cell not in group.cells: group.cells.append(cell)
    lines.remove_at(j)
    again = true
  if group.shape and rules.has("tsquare"): group.length = maxi(5,group.length)
  if rules.has("labyrinth") and group.length < 4: continue
  merged.append(group)
 return merged
func adjacent(a: int,b: int) -> bool:
 var delta: Vector2i = (xy(a)-xy(b)).abs()
 return delta.x+delta.y == 1
func swap(a: int,b: int) -> void:
 var temp: CandyState = cells[a]
 cells[a] = cells[b]
 cells[b] = temp
func legal_moves() -> Array[Vector2i]:
 var result: Array[Vector2i] = []
 for a: int in range(cells.size()):
  if not playable(a): continue
  for step: Vector2i in [Vector2i.RIGHT,Vector2i.DOWN]:
   var p: Vector2i = xy(a)+step
   if not inside(p): continue
   var b: int = index(p)
   if not playable(b): continue
   swap(a,b)
   if cells[a].coating == 3 or cells[b].coating == 3 or not matches().is_empty(): result.append(Vector2i(a,b))
   swap(a,b)
 return result
func reshuffle() -> void:
 var movable: Array[int] = []
 for i: int in range(cells.size()):
  if playable(i): movable.append(i)
 for attempt: int in range(100):
  for j: int in range(movable.size()-1,0,-1): swap(movable[j],movable[rng.randi_range(0,j)])
  if matches().is_empty() and not legal_moves().is_empty(): return
 # Recovery for pathological rules or almost completely blocked boards.
 for i: int in range(cells.size()):
  if cells[i].blocker > 0: graves.append(i)
  cells[i].blocker = 0
 for attempt: int in range(100):
  for cell: CandyState in cells: cell.color = roll_color()
  stabilize()
  if not legal_moves().is_empty(): return
func wild_groups(a: int,b: int) -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for color: int in range(config.candies.size()):
  var ids: Array[int] = []
  for i: int in [a,b]:
   if cells[i].color == color: ids.append(i)
  for i: int in range(cells.size()):
   if ids.size() >= 3: break
   if same(i,color) and i not in ids: ids.append(i)
  if not ids.is_empty(): result.append({"cells":ids,"color":color,"length":3,"diagonal":false,"shape":false,"axis":Vector2i.RIGHT,"synthetic":true})
 return result
func expand(group: Dictionary) -> Dictionary:
 var ids: Array[int] = []
 for i: int in group.cells: ids.append(i)
 var origin: int = ids[0]
 var color: int = group.color
 var effect: String = ""
 var bonus: int = 0
 var wild: int = -1
 var effects: Array[String] = []
 if group.cells.size() == 3 and not group.get("synthetic",false): effects.append_array(rules.modifiers("Three"))
 if group.length >= 4: effects.append_array(rules.modifiers("Four"))
 if group.length >= 5: effects.append_array(rules.modifiers("Five"))
 if effects.is_empty():
  if group.length == 4: effects.append("line")
  elif group.length >= 5: effects.append("color")
 # Repainting happens first so attraction and gilding can use the new color.
 var order: Array[String] = ["golden_trio","pop_rock","sweet_tooth","three_scoops","paintball","gravity","sledgehammer","ricochet","necro","midas","nuclear","prism","line","color"]
 for active: String in order:
  if active not in effects: continue
  effect = active
  match effect:
   "golden_trio":
    for i: int in group.cells:
     if cells[i] != null: cells[i].coating = 2
   "pop_rock":
    # The middle candy anchors the blast, including diagonal and wrapped runs.
    var center: Vector2i = xy(group.cells[1])
    for dy: int in range(-1,2):
     for dx: int in range(-1,2):
      var p: Vector2i = center+Vector2i(dx,dy)
      if inside(p) and index(p) not in ids: ids.append(index(p))
   "sweet_tooth":
    var candidates: Array[int] = []
    for i: int in range(cells.size()):
     if cells[i] != null and cells[i].color == color and cells[i].blocker == 0 and i not in ids: candidates.append(i)
    candidates.sort_custom(func(a: int,b: int) -> bool: return xy(a).distance_squared_to(xy(origin)) < xy(b).distance_squared_to(xy(origin)))
    for i: int in range(mini(2,candidates.size())): ids.append(candidates[i])
   "three_scoops": bonus += 30
   "gravity":
    var candidates: Array[int] = []
    for i: int in range(cells.size()):
     if cells[i] != null and cells[i].color == color and cells[i].blocker == 0 and i not in ids: candidates.append(i)
    candidates.sort_custom(func(a: int,b: int) -> bool: return xy(a).distance_squared_to(xy(origin)) < xy(b).distance_squared_to(xy(origin)))
    for i: int in range(mini(int(rules.power("gravity",4)),candidates.size())): ids.append(candidates[i])
   "paintball":
    for i: int in group.cells:
     for d: Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
      var p: Vector2i = xy(i)+d
      if inside(p) and index(p) not in ids and cells[index(p)] != null and cells[index(p)].blocker == 0: cells[index(p)].color = color
   "sledgehammer":
    var best: int = -1
    for i: int in range(cells.size()):
     if cells[i] != null and cells[i].blocker > 0 and (best < 0 or cells[i].blocker > cells[best].blocker): best = i
    if best >= 0: ids.append(best)
    else: bonus += int(rules.power("sledgehammer",30))
   "ricochet", "line":
    for i: int in range(cells.size()):
     if (xy(i).y == xy(origin).y if group.axis.x != 0 else xy(i).x == xy(origin).x):
      if i not in ids: ids.append(i)
      if effect == "ricochet" and i not in group.cells and cells[i] != null and cells[i].blocker == 0:
       var coated: CandyState = CandyState.new(cells[i].color)
       coated.coating = 1
       recycled.append(coated)
   "nuclear":
    for dy: int in range(-1,2):
     for dx: int in range(-1,2):
      var p: Vector2i = xy(origin)+Vector2i(dx,dy)
      if inside(p) and index(p) not in ids: ids.append(index(p))
   "midas":
    for cell: CandyState in cells:
     if cell != null and cell.color == color and cell.blocker == 0: cell.coating = 2
   "prism": wild = origin
   "necro":
    for i: int in range(cells.size()):
     if i in graves or (cells[i] != null and cells[i].blocker > 0):
      cells[i] = CandyState.new(roll_color())
      cells[i].coating = 2
    graves.clear()
   "color":
    for i: int in range(cells.size()):
     if cells[i] != null and cells[i].color == color and i not in ids: ids.append(i)
 # Only neighbors of the original match break; destruction never floods outward.
 if group.cells.size() >= 3:
  for matched: int in group.cells:
   for direction: Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
    var neighbor: Vector2i = xy(matched)+direction
    if inside(neighbor) and is_locked_tile(index(neighbor)) and index(neighbor) not in ids:
     ids.append(index(neighbor))
 var chips: int = bonus
 var isotope: bool = false
 var contributions: Dictionary = {}
 var broken: Array[int] = []
 var break_bonus: int = 50 if group.length >= 5 else (25 if group.length >= 4 else 10)
 for i: int in ids:
  var value: int = 0
  if cells[i] != null:
   value = cells[i].chips(config)
   if is_locked_tile(i):
    # Blockers hide a real candy; award its value as well as the breaking bonus.
    if cells[i].blocker > 0:
     value = config.gold_chips if cells[i].coating == 2 else (config.caramel_chips if cells[i].coating == 1 else config.candies[cells[i].color].base_chips)
    value += break_bonus
    broken.append(i)
  contributions[i] = value
  chips += value
  if i in isotopes: isotope = true
 # Isotopes affect later matches, not their own creation.
 if "nuclear" in effects and origin not in isotopes: isotopes.append(origin)
 return {"cells":ids,"chips":chips,"isotope":isotope,"effect":" + ".join(effects),"effects":effects,"wild":wild,"color":color,"origin":origin,"contributions":contributions,"broken":broken,"break_bonus":break_bonus}
func remove(ids: Array[int]) -> void:
 for i: int in ids:
  if cells[i] != null and cells[i].blocker > 0 and i not in graves: graves.append(i)
  cells[i] = null
func refill() -> void:
 # Blockers and locked colors are fixed anchors. Compact each segment separately.
 for x: int in range(width):
  var bottom: int = height-1
  for y: int in range(height-1,-2,-1):
   var anchor: bool = y == -1
   if y >= 0:
    var cell: CandyState = cells[y*width+x]
    anchor = cell != null and (cell.blocker > 0 or cell.color == locked_color)
   if not anchor: continue
   var write_y: int = bottom
   for scan: int in range(bottom,y,-1):
    if cells[scan*width+x] != null:
     cells[write_y*width+x] = cells[scan*width+x]
     if write_y != scan:
      cells[write_y*width+x].age = -1
      cells[scan*width+x] = null
     write_y -= 1
   while write_y > y:
    cells[write_y*width+x] = recycled.pop_back() if not recycled.is_empty() else CandyState.new(roll_color())
    cells[write_y*width+x].age = -1
    write_y -= 1
   bottom = y-1
func age_candies(touched: Array[int]) -> void:
 for i: int in range(cells.size()):
  if cells[i] == null or cells[i].blocker > 0: continue
  cells[i].age = 0 if i in touched else cells[i].age+1
  if cells[i].age >= config.heatwave_turns: cells[i].blocker = 1
