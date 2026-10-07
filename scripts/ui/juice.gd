class_name SugarJuice
extends Node2D
@export var float_duration: float = 0.9
@export var particle_count: int = 14
func popup(text: String, point: Vector2, color: Color = UIStyle.CREAM) -> void:
 var label: Label = UIStyle.label(text,22,color)
 label.position = point-Vector2(30,15)
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(label)
 var tween: Tween = label.create_tween().set_parallel()
 tween.tween_property(label,"position:y",point.y-(58 if GameManager.motion else 20),float_duration)
 tween.tween_property(label,"modulate:a",0.0,float_duration).set_delay(0.2)
 tween.chain().tween_callback(label.queue_free)
func burst(point: Vector2, color: Color) -> void:
 if not GameManager.motion: return
 var particles: CPUParticles2D = CPUParticles2D.new()
 particles.position = point
 particles.texture = UIStyle.texture("ui_particle")
 particles.amount = particle_count
 particles.lifetime = 0.45
 particles.one_shot = true
 particles.explosiveness = 1.0
 particles.direction = Vector2.UP
 particles.spread = 180
 particles.initial_velocity_min = 35
 particles.initial_velocity_max = 115
 particles.gravity = Vector2(0,160)
 particles.scale_amount_min = 0.08
 particles.scale_amount_max = 0.16
 particles.color = color
 add_child(particles)
 particles.emitting = true
 get_tree().create_timer(0.8).timeout.connect(particles.queue_free)
func clear_effects() -> void:
 for child: Node in get_children(): child.queue_free()
