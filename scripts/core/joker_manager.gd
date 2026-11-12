class_name JokerManager
extends Node
signal changed
@export var capacity: int = 5
# Order matters: Jokers score left to right.
var equipped: Array[JokerData] = []
var editions: Dictionary = {} # Joker id -> EditionCatalog id
var counters: Dictionary = {} # Joker id -> growth of a scaling Joker this run
func has(id: String) -> bool:
 for item: JokerData in equipped:
  if item.id == id: return true
 return false
func power(id: String, fallback: float = 1.0) -> float:
 for item: JokerData in equipped:
  if item.id == id: return item.strength
 return fallback
func modifiers(category: String) -> Array[String]:
 var result: Array[String] = []
 for item: JokerData in equipped:
  if item.category == category: result.append(item.id)
 result.sort()
 return result
func can_add(item: JokerData) -> bool:
 return equipped.size() < capacity and not has(item.id)
func add(item: JokerData, edition: String = "") -> bool:
 if not can_add(item): return false
 equipped.append(item)
 if not edition.is_empty(): editions[item.id] = edition
 changed.emit()
 return true
func remove(item: JokerData) -> void:
 equipped.erase(item)
 editions.erase(item.id)
 counters.erase(item.id)
 changed.emit()
func edition(id: String) -> String:
 return String(editions.get(id,""))
func counter(id: String) -> float:
 return float(counters.get(id,0.0))
func grow(id: String, amount: float) -> void:
 if has(id): counters[id] = counter(id)+amount
# Move an owned Joker left (-1) or right (+1).
func move(item: JokerData, delta: int) -> bool:
 var from: int = equipped.find(item)
 var to: int = from+delta
 if from < 0 or to < 0 or to >= equipped.size(): return false
 equipped.remove_at(from)
 equipped.insert(to,item)
 changed.emit()
 return true
func clear_all() -> void:
 equipped.clear()
 editions.clear()
 counters.clear()
