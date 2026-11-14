class_name MovingPlatform
extends AnimatableBody2D
## Bewegliche Plattform (sinusförmig). CharacterBody2D nimmt die Plattformbewegung automatisch mit.

const SIZE := Vector2(96, 16)
var origin: Vector2 = Vector2.ZERO
var axis: Vector2 = Vector2.RIGHT
var amplitude: float = 96.0
var speed: float = 1.1
var _t: float = 0.0

func setup(center: Vector2, vertical: bool, phase: float = 0.0) -> void:
	origin = center
	position = center
	axis = Vector2.DOWN if vertical else Vector2.RIGHT
	_t = phase
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	var cs := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = SIZE
	cs.shape = s
	add_child(cs)

func _physics_process(delta: float) -> void:
	_t += delta * speed
	position = origin + axis * sin(_t) * amplitude

func _draw() -> void:
	TerrainArt.draw_platform(self, Rect2(-SIZE * 0.5, SIZE))
