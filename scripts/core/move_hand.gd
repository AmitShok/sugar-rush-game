class_name MoveHand
extends RefCounted
# One move = one hand (v0.34, Balatro-style). Every group a move clears, in every cascade wave,
# feeds a single Candys x Mult score that is calculated ONCE, so Joker multipliers apply once per
# move instead of once per cascade group.
#
#  - Your own match (wave 0) is the hand: its best group sets the recipe (Quad, Shape...) and each
#    extra wave-0 group adds +EXTRA_GROUP_MULT Mult. This part is deterministic, so the board can
#    preview it exactly before you commit (the "floor").
#  - Cascades only ADD: their candies add Candys, fired specials add Mult and each wave adds the
#    cascade Mult step (RunConfig.cascade_mult_step, capped). The preview is never an overestimate.
#  - Jokers, editions and boss rules then scale the totals once (ScoreEngine.calculate).
const EXTRA_GROUP_MULT: float = 1.0
var candys: int = 0
var best: Dictionary = {}
var best_rank: float = -1.0
var best_wave: int = 0
var extra_groups: int = 0
var waves: int = 0
var special_mult: float = 0.0
var combo_x: float = 1.0
var curse_mult: float = 1.0
var isotope: bool = false
var poisoned: bool = false
var diagonal: bool = false
var fired: int = 0
var groups: int = 0
var direct_only: bool = true

# Ranks recipes so the hand takes your strongest match (bigger Mult first, then Candys).
static func rank(group: Dictionary, levels: Dictionary) -> float:
 var recipe: String = RecipeCatalog.classify(group)
 var lvl: int = RecipeCatalog.level(levels,recipe)
 return float(RecipeCatalog.mult(recipe,lvl)+RecipeCatalog.extra_mult(recipe,int(group.get("length",3))))*1000.0+float(RecipeCatalog.candys(recipe,lvl))

# Adds one scored group. chips is the group's Candys after removing overlap with other groups.
func add(group: Dictionary, chips: int, effect: Dictionary, wave: int, levels: Dictionary, poison: int) -> void:
 groups += 1
 candys += maxi(0,chips)
 waves = maxi(waves,wave)
 fired += int(effect.get("fired",[]).size()) if effect.get("fired",[]) is Array else 0
 special_mult += float(group.get("special_mult",0))
 combo_x = maxf(combo_x,float(group.get("combo_x",1.0)))
 curse_mult = minf(curse_mult,float(group.get("curse_mult",1.0)))
 isotope = isotope or bool(effect.get("isotope",false))
 if group.get("direct",false): return
 direct_only = false
 if poison >= 0 and int(group.get("color",-1)) == poison: poisoned = true
 # Only your own match decides the hand; a consumable-started move falls back to its first wave.
 var hand_wave: bool = wave == 0 or best.is_empty() or wave == best_wave
 if not hand_wave: return
 if wave == 0 and bool(group.get("diagonal",false)): diagonal = true
 var value: float = rank(group,levels)
 if best.is_empty():
  best = group.duplicate()
  best_rank = value
  best_wave = wave
  return
 extra_groups += 1
 if value > best_rank:
  best = group.duplicate()
  best_rank = value

# The hand's score with Jokers applied. Safe to call at any time (it is monotonic as waves add).
func result(jokers: JokerManager, streak: int, final_move: bool, population: int, levels: Dictionary) -> Dictionary:
 if direct_only or best.is_empty():
  return {"chips":float(candys),"mult":1.0,"total":candys,"recipe":"","level":0,"fired":fired,"color":-1}
 var hand: Dictionary = best.duplicate()
 hand["special_mult"] = special_mult+extra_groups*EXTRA_GROUP_MULT
 hand["combo_x"] = combo_x
 hand["curse_mult"] = curse_mult
 hand["diagonal"] = diagonal or bool(best.get("diagonal",false))
 var scored: Dictionary = ScoreEngine.calculate(candys,hand,isotope,jokers,streak,poisoned,final_move,population,waves,levels)
 scored["fired"] = fired
 scored["color"] = int(best.get("color",-1))
 scored["poisoned"] = poisoned
 scored["groups"] = groups
 scored["waves"] = waves
 return scored
