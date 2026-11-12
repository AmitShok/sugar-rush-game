class_name ScoreEngine
extends RefCounted
# Tuning shared by the live board, tests and balance tools. GameManager copies these from RunConfig.
static var cascade_step: float = 0.5
static var cascade_cap: float = 2.0
static func configure(config: RunConfig) -> void:
 cascade_step = config.cascade_mult_step
 cascade_cap = config.cascade_mult_cap
# levels: recipe id -> level (missing ids are level 1). See RecipeCatalog.
# Jokers score left to right; each applies its own effect, then its edition.
static func calculate(chips: int, group: Dictionary, isotope: bool, jokers: JokerManager, streak: int, poisoned: bool, final_move: bool, population: int, cascade: int, levels: Dictionary = {}) -> Dictionary:
 var recipe: String = RecipeCatalog.classify(group)
 var lvl: int = RecipeCatalog.level(levels,recipe)
 var base: float = chips + RecipeCatalog.candys(recipe,lvl)
 var mult: float = RecipeCatalog.mult(recipe,lvl) + RecipeCatalog.extra_mult(recipe,int(group.length)) + minf(cascade*cascade_step,cascade_cap)
 # Special candies fired by this group add Mult; special-swap combos multiply it.
 mult += float(group.get("special_mult",0))
 mult *= float(group.get("combo_x",1.0))
 for item: JokerData in jokers.equipped:
  match item.id:
   "kaleidoscope": if group.diagonal: base *= item.strength
   "labyrinth": mult *= item.strength
   "addict": mult += streak*item.strength
   "nuclear": if isotope: mult *= item.strength
   "roulette": if poisoned: mult *= item.strength
   "ouroboros": if final_move: mult *= maxf(1.0,population*item.strength)
   "sugar_cube": mult += jokers.counter(item.id)
   "gumball_jar": base += jokers.counter(item.id)
   "candy_cane": mult *= 1.0+jokers.counter(item.id)
  var edition: String = jokers.edition(item.id)
  if not edition.is_empty():
   base += float(EditionCatalog.ITEMS[edition].candys)
   mult += float(EditionCatalog.ITEMS[edition].mult)
   mult *= float(EditionCatalog.ITEMS[edition].x_mult)
 # Boss rules (Jelly Mould, Tiny Spoon) scale the final Mult.
 mult *= float(group.get("curse_mult",1.0))
 var value: int = roundi(base*mult)
 if jokers.has("broken"): return {"chips":mult,"mult":base,"total":value,"recipe":recipe,"level":lvl}
 return {"chips":base,"mult":mult,"total":value,"recipe":recipe,"level":lvl}
