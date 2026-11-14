class_name Weapon
extends Node2D
## Waffe: zielt zur Maus, schießt, verwaltet Cooldown/Munition-Verbrauch und Mündungsblitz.
## Child "Weapon" des Players.

var aim: Vector2 = Vector2.RIGHT
var cooldown: float = 0.0
var flash: float = 0.0
var _empty_clicked: bool = false

@onready var player: Player = get_parent() as Player

func _process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	flash = maxf(0.0, flash - delta)
	if player.alive:
		var d: Vector2 = get_global_mouse_position() - player.global_position
		if d.length() > 6.0:
			aim = d.normalized()
		rotation = aim.angle()
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_empty_clicked = false
	queue_redraw()

## Klick-Ereignis direkt abfangen (UI kann es nicht schlucken, sehr kurze Klicks gehen nicht verloren).
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		try_shoot()

func try_shoot() -> void:
	if player == null or not player.alive or get_tree().paused or not player.is_physics_processing():
		return
	if cooldown > 0.0:
		return
	if player.ammo <= 0:
		if not _empty_clicked:
			_empty_clicked = true
			cooldown = 0.12
			Sfx.play("empty")
		return
	cooldown = GameManager.shoot_cooldown
	flash = 0.07
	player.ammo -= 1
	player.apply_recoil(-aim)
	var level: Node = player.get_parent()
	var muzzle: Vector2 = player.global_position + aim * 20.0
	Fx.burst(level, muzzle, aim, Color(2.5, 1.8, 0.6), 10, 380.0, 18.0, 0.25, 3.0)
	Fx.burst(level, player.global_position, -aim, Color(1.2, 1.2, 1.6), 6, 140.0, 40.0, 0.3, 2.5)
	player.camera.add_trauma(0.28)
	Sfx.play("shot", 0.08)

func _draw() -> void:
	if player == null or not player.alive:
		return
	draw_rect(Rect2(5, -2, 13, 4), Color(0.12, 0.16, 0.26))
	draw_rect(Rect2(5, -2, 13, 4), Color(2.0, 1.5, 0.4), false, 1.0)
	if flash > 0.0:
		var a: float = flash / 0.07
		draw_colored_polygon(PackedVector2Array([Vector2(18, 0), Vector2(26, -5.0 * a - 1.0), Vector2(40, 0), Vector2(26, 5.0 * a + 1.0)]), Color(2.5, 2.0, 0.8, a))
		draw_line(Vector2(20, 0), Vector2(160, 0), Color(2.0, 1.8, 1.0, a * 0.6), 2.0)
