class_name BossCatalog
extends RefCounted
# Boss rules. Each run draws one boss per ante from this pool, without repeats, from the run seed.
const ORDER: Array[String] = ["inspector","heatwave","chocolatier","frost","sour","spoon","jelly","tax","hurry"]
const ITEMS: Dictionary = {
 "inspector": {"name":"The Inspector","short":"INSPECTOR","description":"One candy type stays put in falls. Match 3 with it to break it."},
 "heatwave": {"name":"The Heatwave","short":"HEATWAVE","description":"Candies untouched for 4 moves become sticky blockers."},
 "chocolatier": {"name":"The Chocolatier","short":"CHOCOLATIER","description":"Chocolate spreads after any move that breaks none."},
 "frost": {"name":"The Frost","short":"FROST","description":"Double frosting blocks the middle. Nearby matches chip it."},
 "sour": {"name":"The Sour Patch","short":"SOUR PATCH","description":"One candy type is sour and scores 0 Candys."},
 "spoon": {"name":"The Tiny Spoon","short":"TINY SPOON","description":"All Mult is halved this round."},
 "jelly": {"name":"The Jelly Mould","short":"JELLY MOULD","description":"Half the board is jelly. Matches that clear no jelly score half."},
 "tax": {"name":"The Sugar Tax","short":"SUGAR TAX","description":"Every move costs $1 while you have cash."},
 "hurry": {"name":"The Rush Hour","short":"RUSH HOUR","description":"You get 3 fewer moves."},
}
const HURRY_MOVES: int = 3
const TAX: int = 1
const CHOCOLATE_START: Array[int] = [17,22,41,46]
const FROST_START: Array[int] = [26,27,28,29,34,35,36,37]
const FROST_LAYERS: int = 2
static func for_run(run_seed: int) -> Array[String]:
 var rng: RandomNumberGenerator = RandomNumberGenerator.new()
 rng.seed = hash([run_seed,"bosses"])
 var pool: Array[String] = ORDER.duplicate()
 var result: Array[String] = []
 for ante: int in range(6):
  result.append(pool.pop_at(rng.randi_range(0,pool.size()-1)))
 return result
