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
# Boss state (v0.22).
var boss: String = "none"
var jelly: Array[int] = [] # board positions still covered in jelly
var jelly_count: int = 24 # How many jelly tiles The Jelly Mould lays (BossCatalog.jelly_count by ante).
var sour_color: int = -1
var chocolate_broken: int = 0 # chocolate tiles broken since the last move began
var candy_bonuses: Array[int] = []
# Mult each special adds to the match that fires it (index = CandyState special kind).
const SPECIAL_MULT: Array[int] = [0,4,4,6,10]
const PAINTBALL_WAVES: int = 3
func candy_bonus(color: int) -> int:
 return candy_bonuses[color] if color >= 0 and color < candy_bonuses.size() else 0
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
 return cells[i] != null and (cells[i].blocker > 0 or cells[i].color == locked_color or cells[i].obstacle())
func xy(i: int) -> Vector2i:
 return Vector2i(i % width, i / width)
func index(p: Vector2i) -> int:
 return p.y * width + p.x
func inside(p: Vector2i) -> bool:
 return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height
func playable(i: int) -> bool:
 return i >= 0 and i < cells.size() and cells[i] != null and cells[i].blocker == 0 and not cells[i].obstacle()
func matchable(i: int) -> bool:
 return i >= 0 and i < cells.size() and cells[i] != null and cells[i].coating != 3 and cells[i].special != CandyState.BOMB and not cells[i].obstacle()
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
   if cells[a].coating == 3 or cells[b].coating == 3 or is_special_swap(a,b) or not matches().is_empty(): result.append(Vector2i(a,b))
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
func shake_candies() -> bool:
 # Reorder existing candies only. Locks, coatings, ages and board marks survive.
 var original: Array[CandyState]=cells.duplicate()
 var movable: Array[int]=[]
 for i: int in range(cells.size()):
  if cells[i] != null and not is_locked_tile(i): movable.append(i)
 for attempt: int in range(200):
  for j: int in range(movable.size()-1,0,-1): swap(movable[j],movable[rng.randi_range(0,j)])
  var different: bool=false
  for i: int in movable:
   if cells[i].color != original[i].color or cells[i].coating != original[i].coating: different=true
  if different and matches().is_empty() and not legal_moves().is_empty(): return true
 cells.assign(original)
 return false
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
 var synthetic: bool = group.get("synthetic",false)
 if group.length >= 4 and not synthetic: effects.append_array(rules.modifiers("Four"))
 if group.length >= 5 and not synthetic: effects.append_array(rules.modifiers("Five"))
 # Paintball splatters on your match and the next PAINTBALL_WAVES cascade waves, so its chains
 # stay fun but cannot feed themselves forever (v0.34).
 if int(group.get("cascade",0)) > PAINTBALL_WAVES: effects.erase("paintball")
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
     if cells[i] != null and cells[i].color == color and cells[i].blocker == 0 and not cells[i].obstacle() and i not in ids: candidates.append(i)
    candidates.sort_custom(func(a: int,b: int) -> bool: return xy(a).distance_squared_to(xy(origin)) < xy(b).distance_squared_to(xy(origin)))
    for i: int in range(mini(2,candidates.size())): ids.append(candidates[i])
   "three_scoops": bonus += 30
   "gravity":
    var candidates: Array[int] = []
    for i: int in range(cells.size()):
     if cells[i] != null and cells[i].color == color and cells[i].blocker == 0 and not cells[i].obstacle() and i not in ids: candidates.append(i)
    candidates.sort_custom(func(a: int,b: int) -> bool: return xy(a).distance_squared_to(xy(origin)) < xy(b).distance_squared_to(xy(origin)))
    for i: int in range(mini(int(rules.power("gravity",4)),candidates.size())): ids.append(candidates[i])
   "paintball":
    for i: int in group.cells:
     for d: Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
      var p: Vector2i = xy(i)+d
      if inside(p) and index(p) not in ids and cells[index(p)] != null and cells[index(p)].blocker == 0 and not cells[index(p)].obstacle(): cells[index(p)].color = color
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
     if cell != null and cell.color == color and cell.blocker == 0 and not cell.obstacle(): cell.coating = 2
   "prism": wild = origin
   "necro":
    for i: int in range(cells.size()):
     if i in graves or (cells[i] != null and cells[i].blocker > 0):
      cells[i] = CandyState.new(roll_color())
      cells[i].coating = 2
    graves.clear()
   "color":
    for i: int in range(cells.size()):
     if cells[i] != null and cells[i].color == color and not cells[i].obstacle() and i not in ids: ids.append(i)
 # Only neighbors of the original match break; destruction never floods outward.
 if group.cells.size() >= 3:
  for matched: int in group.cells:
   for direction: Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
    var neighbor: Vector2i = xy(matched)+direction
    if inside(neighbor) and is_locked_tile(index(neighbor)) and index(neighbor) not in ids:
     ids.append(index(neighbor))
 # Matched or blasted special candies detonate; their blasts can chain into more specials.
 var fired: Array[int] = []
 var special_mult: int = 0
 var k: int = 0
 while k < ids.size():
  var cell_index: int = ids[k]
  k += 1
  if cells[cell_index] == null or cells[cell_index].special == CandyState.NONE or cell_index in fired: continue
  fired.append(cell_index)
  special_mult += SPECIAL_MULT[cells[cell_index].special]
  for j: int in special_blast(cell_index):
   if j not in ids: ids.append(j)
 # Special-maker Jokers leave a new special where the match was made (the swapped cell when possible).
 var spawn: Dictionary = {}
 if not synthetic:
  var pivot: int = int(group.get("pivot",group.cells[group.cells.size()/2]))
  var line: bool = not group.shape
  if group.shape and rules.has("wrapper"): spawn = {"index":pivot,"special":CandyState.WRAPPED,"color":color}
  elif line and group.length >= 5 and rules.has("bomb_maker"): spawn = {"index":pivot,"special":CandyState.BOMB,"color":color}
  elif line and group.length >= 4 and rules.has("striper"):
   var horizontal: bool = group.axis == Vector2i.RIGHT
   spawn = {"index":pivot,"special":CandyState.STRIPE_V if horizontal else CandyState.STRIPE_H,"color":color}
 group["special_mult"] = special_mult
 var chips: int = bonus
 var isotope: bool = false
 var contributions: Dictionary = {}
 var broken: Array[int] = []
 var break_bonus: int = 50 if group.length >= 5 else (25 if group.length >= 4 else 10)
 # Multi-layer frosting loses one layer per hit and stays until its last layer breaks.
 var survivors: Array[int] = []
 var jelly_cleared: int = 0
 for i: int in ids:
  var value: int = 0
  if cells[i] != null:
   value = cells[i].chips(config,candy_bonus(cells[i].color))
   # The Sour Patch: one candy type is worth nothing (breaking bonuses still count).
   if cells[i].color == sour_color and not cells[i].obstacle(): value = 0
   if is_locked_tile(i):
    # Blockers hide a real candy; award its value as well as the breaking bonus.
    if cells[i].blocker > 0 and cells[i].color != sour_color:
     value = cells[i].value(config,candy_bonus(cells[i].color))
    value += break_bonus
    broken.append(i)
    if cells[i].frosting > 1:
     cells[i].frosting -= 1
     survivors.append(i)
    elif cells[i].chocolate: chocolate_broken += 1
   if i in jelly and not cells[i].obstacle() and i not in survivors:
    jelly_cleared += 1
    jelly.erase(i)
  contributions[i] = value
  chips += value
  if i in isotopes: isotope = true
 for i: int in survivors: ids.erase(i)
 # Boss Mult rules: Tiny Spoon halves everything. (Jelly Mould instead requires clearing all jelly.)
 var curse_mult: float = 1.0
 if boss == "spoon": curse_mult *= 0.5
 group["curse_mult"] = curse_mult
 # Isotopes affect later matches, not their own creation.
 if "nuclear" in effects and origin not in isotopes: isotopes.append(origin)
 return {"cells":ids,"chips":chips,"isotope":isotope,"effect":" + ".join(effects),"effects":effects,"wild":wild,"color":color,"origin":origin,"contributions":contributions,"broken":broken,"break_bonus":break_bonus,"spawn":spawn,"fired":fired,"special_mult":special_mult}
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
    anchor = cell != null and (cell.blocker > 0 or cell.color == locked_color or cell.obstacle())
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
  if cells[i] == null or cells[i].blocker > 0 or cells[i].obstacle(): continue
  cells[i].age = 0 if i in touched else cells[i].age+1
  if cells[i].age >= config.heatwave_turns: cells[i].blocker = 1
func special_blast(i: int) -> Array[int]:
 # Cells cleared when the special candy at i detonates (the candy itself included).
 var result: Array[int] = [i]
 var p: Vector2i = xy(i)
 match cells[i].special:
  CandyState.STRIPE_H:
   for x: int in range(width): result.append(index(Vector2i(x,p.y)))
  CandyState.STRIPE_V:
   for y: int in range(height): result.append(index(Vector2i(p.x,y)))
  CandyState.WRAPPED:
   for dy: int in range(-1,2):
    for dx: int in range(-1,2):
     if inside(p+Vector2i(dx,dy)): result.append(index(p+Vector2i(dx,dy)))
  CandyState.BOMB:
   # A bomb caught in a blast clears one random candy type that is present.
   var present: Array[int] = []
   for cell: CandyState in cells:
    if cell != null and cell.blocker == 0 and not cell.obstacle() and cell.special != CandyState.BOMB and cell.color not in present: present.append(cell.color)
   if not present.is_empty():
    var target: int = present[rng.randi_range(0,present.size()-1)]
    for j: int in range(cells.size()):
     if cells[j] != null and cells[j].color == target and cells[j].special != CandyState.BOMB and not cells[j].obstacle(): result.append(j)
 return result
func is_special_swap(a: int,b: int) -> bool:
 if cells[a] == null or cells[b] == null: return false
 if cells[a].special == CandyState.BOMB or cells[b].special == CandyState.BOMB: return true
 return cells[a].special != CandyState.NONE and cells[b].special != CandyState.NONE
func area(center: int, radius_x: int, radius_y: int) -> Array[int]:
 var result: Array[int] = []
 for dy: int in range(-radius_y,radius_y+1):
  for dx: int in range(-radius_x,radius_x+1):
   var p: Vector2i = xy(center)+Vector2i(dx,dy)
   if inside(p): result.append(index(p))
 return result
func special_swap_groups(a: int,b: int) -> Array[Dictionary]:
 # Called after the swap. b is the cell the player moved onto. Both specials are consumed here,
 # so the returned group's cells say exactly what clears (newly marked specials still chain).
 var first: CandyState = cells[a]
 var second: CandyState = cells[b]
 var kinds: Array[int] = [first.special,second.special]
 var ids: Array[int] = []
 var color: int = second.color if second.special != CandyState.BOMB else first.color
 if kinds.count(CandyState.BOMB) == 2:
  for i: int in range(cells.size()): ids.append(i)
  first.special = CandyState.NONE
  second.special = CandyState.NONE
 elif CandyState.BOMB in kinds:
  var bomb: int = a if first.special == CandyState.BOMB else b
  var other: int = b if bomb == a else a
  var partner: int = cells[other].special
  color = cells[other].color
  cells[bomb].special = CandyState.NONE
  ids.append(bomb)
  for i: int in range(cells.size()):
   if cells[i] == null or cells[i].blocker > 0 or cells[i].obstacle() or cells[i].color != color or cells[i].special == CandyState.BOMB: continue
   if partner in [CandyState.STRIPE_H,CandyState.STRIPE_V]: cells[i].special = CandyState.STRIPE_H if rng.randi_range(0,1) == 0 else CandyState.STRIPE_V
   elif partner == CandyState.WRAPPED: cells[i].special = CandyState.WRAPPED
   if i not in ids: ids.append(i)
  if partner == CandyState.NONE: cells[other].special = CandyState.NONE
 else:
  var stripes: int = 0
  for kind: int in kinds:
   if kind in [CandyState.STRIPE_H,CandyState.STRIPE_V]: stripes += 1
  first.special = CandyState.NONE
  second.special = CandyState.NONE
  var p: Vector2i = xy(b)
  if stripes == 2:
   for x: int in range(width): ids.append(index(Vector2i(x,p.y)))
   for y: int in range(height):
    if index(Vector2i(p.x,y)) not in ids: ids.append(index(Vector2i(p.x,y)))
  elif stripes == 1:
   for i: int in range(cells.size()):
    var q: Vector2i = xy(i)
    if absi(q.y-p.y) <= 1 or absi(q.x-p.x) <= 1: ids.append(i)
  else:
   ids = area(b,2,2)
 if a not in ids: ids.append(a)
 if b not in ids: ids.append(b)
 var combo_x: float = 6.0 if kinds.count(CandyState.BOMB) == 2 else 3.0
 return [{"cells":ids,"color":color,"length":5,"diagonal":false,"shape":false,"axis":Vector2i.RIGHT,"synthetic":true,"special_swap":true,"combo_x":combo_x}]
func place_spawn(spawn: Dictionary) -> void:
 if spawn.is_empty(): return
 var made: CandyState = CandyState.new(int(spawn.color))
 made.special = int(spawn.special)
 made.age = -1
 cells[int(spawn.index)] = made
# The Chocolatier: if a move broke no chocolate, one candy next to chocolate turns into chocolate.
func spread_chocolate() -> int:
 if chocolate_broken > 0: return -1
 var targets: Array[int] = []
 for i: int in range(cells.size()):
  if cells[i] == null or not cells[i].chocolate: continue
  for d: Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   var p: Vector2i = xy(i)+d
   if not inside(p): continue
   var j: int = index(p)
   var cell: CandyState = cells[j]
   if cell != null and not cell.obstacle() and cell.blocker == 0 and cell.special == CandyState.NONE and j not in targets: targets.append(j)
 if targets.is_empty(): return -1
 var target: int = targets[rng.randi_range(0,targets.size()-1)]
 cells[target].chocolate = true
 cells[target].coating = 0
 return target
func setup_boss(kind: String) -> void:
 # Called after fill_fresh: places this boss's obstacles and board rules.
 boss = kind
 jelly.clear()
 sour_color = -1
 chocolate_broken = 0
 match kind:
  "chocolatier":
   for i: int in BossCatalog.CHOCOLATE_START:
    if i < cells.size(): cells[i].chocolate = true
  "frost":
   for i: int in BossCatalog.FROST_START:
    if i < cells.size(): cells[i].frosting = BossCatalog.FROST_LAYERS
  "jelly": jelly.assign(BossCatalog.jelly_cells(width,height,jelly_count))
  "sour": sour_color = rng.randi_range(0,config.candies.size()-1)

# --- Moves as hands (v0.34) ---
# Groups made by swapping a and b. Call AFTER swap(a,b); specials and wilds are symmetric.
func swap_groups(a: int, b: int) -> Array[Dictionary]:
 if is_special_swap(a,b): return special_swap_groups(a,b)
 if (cells[a] != null and cells[a].coating == 3) or (cells[b] != null and cells[b].coating == 3): return wild_groups(a,b)
 var groups: Array[Dictionary] = matches()
 # New specials appear where the player moved a candy.
 for group: Dictionary in groups:
  if b in group.cells: group["pivot"] = b
  elif a in group.cells: group["pivot"] = a
 return groups

# Everything expand() may change, so a move can be tried and undone exactly.
func snapshot() -> Dictionary:
 var copies: Array[CandyState] = []
 for cell: CandyState in cells:
  if cell == null:
   copies.append(null)
   continue
  var copy: CandyState = CandyState.new(cell.color)
  copy.coating = cell.coating
  copy.blocker = cell.blocker
  copy.age = cell.age
  copy.special = cell.special
  copy.chocolate = cell.chocolate
  copy.frosting = cell.frosting
  copies.append(copy)
 return {"cells":copies,"rng":rng.state,"isotopes":isotopes.duplicate(),"graves":graves.duplicate(),"jelly":jelly.duplicate(),"chocolate_broken":chocolate_broken,"recycled":recycled.size()}

func restore(snap: Dictionary) -> void:
 cells.assign(snap.cells)
 rng.state = int(snap.rng)
 isotopes.assign(snap.isotopes)
 graves.assign(snap.graves)
 jelly.assign(snap.jelly)
 chocolate_broken = int(snap.chocolate_broken)
 recycled.resize(int(snap.recycled))

# Scores one cascade wave into a hand. Each candy is counted once per wave even when effects overlap.
# Returns {"removed","effects","chips"} so the board can animate exactly what it scored.
func score_wave(groups: Array[Dictionary], wave: int, hand: MoveHand, levels: Dictionary, poison: int) -> Dictionary:
 var removed: Array[int] = []
 var effects: Array[Dictionary] = []
 var chips_list: Array[int] = []
 for group: Dictionary in groups:
  group["cascade"] = wave # Paintball only fires on wave 0 (your own match).
  var effect: Dictionary = expand(group)
  var chips: int = int(effect.chips)
  for i: int in effect.cells:
   if i in removed and cells[i] != null: chips -= int(effect.contributions[i])
   elif i not in removed: removed.append(i)
  hand.add(group,chips,effect,wave,levels,poison)
  effects.append(effect)
  chips_list.append(maxi(0,chips))
 return {"removed":removed,"effects":effects,"chips":chips_list}

# Exact preview of swapping a and b: the guaranteed part of the hand (your own match, before any
# cascade). The board is left exactly as it was. "cells" lists every candy the match would clear.
func preview_swap(a: int, b: int, levels: Dictionary, poison: int) -> Dictionary:
 if not adjacent(a,b) or not playable(a) or not playable(b): return {"valid":false,"hand":null,"cells":[]}
 var snap: Dictionary = snapshot()
 swap(a,b)
 var groups: Array[Dictionary] = swap_groups(a,b)
 var hand: MoveHand = MoveHand.new()
 var cleared: Array[int] = []
 if not groups.is_empty():
  cleared = score_wave(groups,0,hand,levels,poison).removed
 restore(snap)
 return {"valid":not groups.is_empty(),"hand":hand,"cells":cleared}
