class_name EditionCatalog
extends RefCounted
# Joker editions (Balatro-style). An edition belongs to one owned Joker and applies to every scored match.
const ORDER: Array[String] = ["foil","holo","poly"]
const ITEMS: Dictionary = {
 "foil": {"name":"Foil","effect":"+50 Candys","candys":50,"mult":0,"x_mult":1.0,"price":2,"chance":0.08,"tint":"9fd8f0"},
 "holo": {"name":"Holographic","effect":"+4 Mult","candys":0,"mult":4,"x_mult":1.0,"price":3,"chance":0.05,"tint":"f4a3c0"},
 "poly": {"name":"Polychrome","effect":"x1.5 Mult","candys":0,"mult":0,"x_mult":1.5,"price":5,"chance":0.03,"tint":"f4c76b"},
}
# Deterministic per run, shop and offer, so seeded runs reproduce and the main RNG is untouched.
static func roll(key: Array) -> String:
 var rng: RandomNumberGenerator = RandomNumberGenerator.new()
 rng.seed = hash(key)
 var r: float = rng.randf()
 for id: String in ORDER:
  r -= float(ITEMS[id].chance)
  if r < 0.0: return id
 return ""
static func price_bonus(edition: String) -> int:
 return int(ITEMS[edition].price) if ITEMS.has(edition) else 0
static func label(edition: String) -> String:
 return "%s: %s" % [ITEMS[edition].name,ITEMS[edition].effect] if ITEMS.has(edition) else ""
