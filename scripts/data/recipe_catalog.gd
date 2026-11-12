class_name RecipeCatalog
extends RefCounted
# Match "hand types". Every scored group uses exactly one recipe; its Candys are added before Mult.
# Levels start at 1 and are bought in the shop for this run only.
const ORDER: Array[String] = ["trio","quad","quint","shape","diagonal"]
const ITEMS: Dictionary = {
 "trio": {"name":"Trio","short":"Trio","shape":"Line of 3","candys":0,"mult":1,"level_candys":10,"level_mult":1,"length":3},
 "quad": {"name":"Quad","short":"Quad","shape":"Line of 4","candys":10,"mult":2,"level_candys":15,"level_mult":1,"length":4},
 "quint": {"name":"Quint","short":"Quint","shape":"Line of 5+ (+1 Mult per extra candy)","candys":30,"mult":3,"level_candys":20,"level_mult":2,"length":5},
 "shape": {"name":"L / T Shape","short":"Shape","shape":"Two lines joined in an L or T","candys":20,"mult":3,"level_candys":20,"level_mult":2,"length":-1},
 "diagonal": {"name":"Diagonal","short":"Diag","shape":"Diagonal line (needs Kaleidoscope; +1 Mult per extra candy)","candys":10,"mult":2,"level_candys":15,"level_mult":1,"length":3},
}
static func classify(group: Dictionary) -> String:
 if group.get("shape",false): return "shape"
 if group.get("diagonal",false): return "diagonal"
 var length: int = int(group.get("length",3))
 if length >= 5: return "quint"
 if length == 4: return "quad"
 return "trio"
static func level(levels: Dictionary, id: String) -> int:
 return maxi(1,int(levels.get(id,1)))
static func candys(id: String, lvl: int) -> int:
 return int(ITEMS[id].candys)+int(ITEMS[id].level_candys)*(lvl-1)
static func mult(id: String, lvl: int) -> int:
 return int(ITEMS[id].mult)+int(ITEMS[id].level_mult)*(lvl-1)
# Extra Mult for lines longer than the recipe's own length (Quint 6+, long diagonals).
static func extra_mult(id: String, length: int) -> int:
 if id in ["quint","diagonal"]: return maxi(0,length-int(ITEMS[id].length))
 return 0
static func default_levels() -> Dictionary:
 var result: Dictionary = {}
 for id: String in ORDER: result[id] = 1
 return result
