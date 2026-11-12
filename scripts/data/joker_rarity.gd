class_name JokerRarity
extends RefCounted
# Joker rarity tiers (v0.33). Each tier gets a share of every shop or pack roll, split evenly between
# the Jokers of that tier still available, so adding a Joker never changes the odds of other tiers.
# Tiers were set from measured solo power (tools/balance_sim.gd solo=1) plus design judgement.
const ORDER: Array[String] = ["Common","Uncommon","Rare","Legendary"]
const WEIGHTS: Dictionary = {"Common":62.0,"Uncommon":27.0,"Rare":9.0,"Legendary":2.0}
const COLORS: Dictionary = {"Common":Color("4cb4ff"),"Uncommon":Color("5fd38d"),"Rare":Color("ff6a5a"),"Legendary":Color("c77dff")}

static func color(tier: String) -> Color:
 return COLORS.get(tier,COLORS.Common)

# Chance (0..1) that one roll lands in this tier when every tier has Jokers available.
static func chance(tier: String) -> float:
 var total: float = 0.0
 for t: String in ORDER: total += float(WEIGHTS[t])
 return float(WEIGHTS.get(tier,0.0))/total

# Weighted pick from Jokers (JokerData) or Joker ids (String). Returns the pool index, or -1 if empty.
static func pick_index(pool: Array, random: RandomNumberGenerator, lookup: Callable = Callable()) -> int:
 if pool.is_empty(): return -1
 var counts: Dictionary = {}
 var tiers: Array[String] = []
 for entry: Variant in pool:
  var tier: String = tier_of(entry,lookup)
  tiers.append(tier)
  counts[tier] = int(counts.get(tier,0))+1
 var total: float = 0.0
 for tier: String in counts: total += float(WEIGHTS.get(tier,1.0))
 var roll: float = random.randf()*total
 # Choose the tier first, then a Joker within it uniformly.
 var chosen: String = tiers[0]
 for tier: String in ORDER:
  if not counts.has(tier): continue
  roll -= float(WEIGHTS[tier])
  chosen = tier
  if roll < 0.0: break
 var within: int = random.randi_range(0,int(counts[chosen])-1)
 for i: int in range(pool.size()):
  if tiers[i] != chosen: continue
  if within == 0: return i
  within -= 1
 return 0

static func tier_of(entry: Variant, lookup: Callable = Callable()) -> String:
 var item: JokerData = entry as JokerData if entry is JokerData else null
 if item == null and lookup.is_valid(): item = lookup.call(String(entry)) as JokerData
 return item.rarity if item != null else "Common"
