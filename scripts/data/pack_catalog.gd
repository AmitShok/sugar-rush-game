class_name PackCatalog
extends RefCounted
# Booster packs (v0.23): buy, open, keep some of the cards inside.
const KINDS: Array[String] = ["joker","recipe","candy","treat","rush"]
const ITEMS: Dictionary = {
 "joker": {"name":"Joker Pack","price":4,"jumbo_price":6,"size":2,"jumbo_size":4,"picks":1,"jumbo_picks":1,"weight":28,"art":"pack_joker","blurb":"Pick a Joker"},
 "recipe": {"name":"Recipe Pack","price":4,"jumbo_price":6,"size":3,"jumbo_size":5,"picks":1,"jumbo_picks":2,"weight":27,"art":"pack_recipe","blurb":"Level up a recipe"},
 "candy": {"name":"Candy Pack","price":3,"jumbo_price":5,"size":3,"jumbo_size":5,"picks":1,"jumbo_picks":2,"weight":25,"art":"pack_candy","blurb":"Upgrade a candy"},
 "treat": {"name":"Treat Pack","price":4,"jumbo_price":6,"size":3,"jumbo_size":4,"picks":1,"jumbo_picks":1,"weight":10,"art":"pack_treat","blurb":"Pick a consumable"},
 "rush": {"name":"Sugar Rush Pack","price":6,"jumbo_price":6,"size":2,"jumbo_size":2,"picks":1,"jumbo_picks":1,"weight":10,"art":"pack_rush","blurb":"Rare, powerful cards"},
}
const JUMBO_CHANCE: float = 0.25
# Rare cards found only in Sugar Rush Packs.
const RUSH: Dictionary = {
 "glitter": {"name":"Glitter","description":"A random Joker gets an edition"},
 "cookbook_blast": {"name":"Cookbook Blast","description":"+1 level to every recipe"},
 "big_spoon": {"name":"Big Spoon","description":"+1 Joker slot, but -$10"},
 "meltdown": {"name":"Meltdown","description":"Destroy a random Joker; another turns Polychrome"},
 "golden_batch": {"name":"Golden Batch","description":"+$20, but your interest cap is halved"},
}
const BIG_SPOON_COST: int = 10
const MAX_JOKER_SLOTS: int = 6
const GOLDEN_BATCH_CASH: int = 20
static func kind_name(pack: Dictionary) -> String:
 return ("Jumbo " if pack.get("jumbo",false) else "")+String(ITEMS[pack.kind].name)
static func price(pack: Dictionary) -> int:
 if pack.get("free",false): return 0
 return int(ITEMS[pack.kind].jumbo_price if pack.get("jumbo",false) else ITEMS[pack.kind].price)
static func size(pack: Dictionary) -> int:
 return int(ITEMS[pack.kind].jumbo_size if pack.get("jumbo",false) else ITEMS[pack.kind].size)
static func picks(pack: Dictionary) -> int:
 return int(ITEMS[pack.kind].jumbo_picks if pack.get("jumbo",false) else ITEMS[pack.kind].picks)
static func roll(key: Array) -> Dictionary:
 var rng: RandomNumberGenerator = RandomNumberGenerator.new()
 rng.seed = hash(key)
 var total: int = 0
 for kind: String in KINDS: total += int(ITEMS[kind].weight)
 var r: int = rng.randi_range(0,total-1)
 var kind_pick: String = KINDS[0]
 for kind: String in KINDS:
  r -= int(ITEMS[kind].weight)
  if r < 0:
   kind_pick = kind
   break
 var jumbo: bool = kind_pick != "rush" and rng.randf() < JUMBO_CHANCE
 return {"kind":kind_pick,"jumbo":jumbo,"free":false}
