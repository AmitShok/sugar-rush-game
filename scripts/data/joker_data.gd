class_name JokerData
extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("Geometry", "Four", "Five", "Chaos", "Supply") var category: String = "Geometry"
@export var price: int = 80
@export var strength: float = 1.0
@export var accent: Color = Color("cdb6ff")
@export var icon: Texture2D

@export var spawn_color: int = -1
@export var spawn_multiplier: float = 2.0
