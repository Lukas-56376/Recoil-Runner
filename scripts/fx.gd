class_name Fx
extends RefCounted
## Statische Helfer für Partikel-Effekte (CPUParticles2D, einmalig, selbstlöschend).

static func burst(parent: Node, pos: Vector2, dir: Vector2, color: Color, amount: int = 12, speed: float = 200.0, spread: float = 35.0, life: float = 0.4, size: float = 3.0) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 1.0
	p.direction = dir
	p.spread = spread
	p.gravity = Vector2(0, 500)
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.scale_amount_min = size * 0.5
	p.scale_amount_max = size
	p.color = color
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = g
	parent.add_child(p)
	p.emitting = true
	parent.get_tree().create_timer(life + 0.3).timeout.connect(p.queue_free)
