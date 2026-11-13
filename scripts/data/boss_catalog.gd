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
 "jelly": {"name":"The Jelly Mould","short":"JELLY MOULD","description":"Jelly covers the board. Clear every jelly tile AND reach the score to win."},
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
# Jelly Mould layout (v0.34): every jelly tile must be cleared to win, so the pattern is sized
# to be clearable within a boss round's moves by a player who aims for it (tools/balance_sim.gd boss=jelly).
# Jelly grows with the ante (v0.35, tuned with tools/run_sim.gd): early bosses stay fair on weak boards.
const JELLY_BY_ANTE: Array[int] = [12,15,18,20,22,24]
static func jelly_count(ante: int) -> int:
 return JELLY_BY_ANTE[clampi(ante,0,JELLY_BY_ANTE.size()-1)]
# Checkerboard tiles (skipping the hard-to-reach top and bottom rows), centre first, up to count.
static func jelly_cells(columns: int, rows: int, count: int = 24) -> Array[int]:
 var result: Array[int] = []
 for y: int in range(1,rows-1):
  for x: int in range(columns):
   if (x+y)%2 == 0: result.append(y*columns+x)
 var centre: Vector2 = Vector2(columns-1,rows-1)*0.5
 result.sort_custom(func(a: int,b: int) -> bool:
  var da: float = Vector2(a%columns,a/columns).distance_squared_to(centre)
  var db: float = Vector2(b%columns,b/columns).distance_squared_to(centre)
  return da < db if da != db else a < b)
 result.resize(mini(count,result.size()))
 result.sort()
 return result
