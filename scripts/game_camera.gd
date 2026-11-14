class_name GameCamera
extends Camera2D
## Kamera mit Trauma-basiertem Screen-Shake. Child des Players.

var trauma: float = 0.0

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 9.0
	make_current()

func add_trauma(amount: float) -> void:
	trauma = minf(1.0, trauma + amount * GameManager.shake_multiplier)

func set_bounds(width_px: float, height_px: float) -> void:
	limit_left = 0
	limit_top = 0
	limit_right = int(width_px)
	limit_bottom = int(height_px)

func _process(delta: float) -> void:
	trauma = maxf(0.0, trauma - delta * 2.2)
	var s: float = trauma * trauma
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 18.0 * s
