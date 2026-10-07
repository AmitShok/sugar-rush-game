class_name JokerManager
extends Node
signal changed
@export var capacity: int = 5
var equipped: Array[JokerData] = []
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
func add(item: JokerData) -> bool:
 if not can_add(item): return false
 equipped.append(item)
 changed.emit()
 return true
func remove(item: JokerData) -> void:
 equipped.erase(item)
 changed.emit()
