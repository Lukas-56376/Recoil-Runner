class_name Player
extends CharacterBody2D
## Spieler: KEINE Laufsteuerung, KEIN Sprung. Bewegung ausschließlich durch Waffenrückstoß.

signal died

var ammo: int = 6
var alive: bool = true
var reload_lock: float = 0.0
var spawn_protect: float = 0.0   # kurze Unverwundbarkeit nach dem Respawn
var visual_scale: Vector2 = Vector2.ONE
var _was_on_floor: bool = false
var _pre_move_vy: float = 0.0

@onready var weapon: Weapon = $Weapon
@onready var camera: GameCamera = $Camera

func _ready() -> void:
	ammo = GameManager.max_ammo
	floor_snap_length = 6.0

func _physics_process(delta: float) -> void:
	if not alive:
		return
	reload_lock = maxf(0.0, reload_lock - delta)
	spawn_protect = maxf(0.0, spawn_protect - delta)

	# Schwerkraft (beim Fallen etwas stärker)
	var g: float = GameManager.gravity
	if velocity.y > 0.0:
		g *= GameManager.fall_gravity_mult
	velocity.y += g * delta

	# Reibung: am Boden stark (man bleibt stehen), in der Luft nur minimal (Momentum bleibt)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, GameManager.ground_friction * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, GameManager.air_drag * delta)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		weapon.try_shoot()

	velocity = velocity.limit_length(GameManager.max_speed)
	_pre_move_vy = velocity.y
	move_and_slide()

	var on_floor: bool = is_on_floor()
	if on_floor and not _was_on_floor and _pre_move_vy > 120.0:
		_on_landed(_pre_move_vy)
	if on_floor and reload_lock <= 0.0 and ammo < GameManager.max_ammo:
		ammo = GameManager.max_ammo
		Sfx.play("reload")
		Fx.burst(get_parent(), global_position + Vector2(0, 14), Vector2.UP, Color(2.0, 1.8, 0.5), 5, 120.0, 90.0, 0.25, 2.0)
	_was_on_floor = on_floor

## Der Kern: Rückstoß in Richtung dir (= entgegengesetzt zur Schussrichtung).
func apply_recoil(dir: Vector2) -> void:
	# Momentum, das dem Rückstoß entgegenläuft, wird (teilweise) gelöscht -> verlässliche, kontrollierbare Flugbahn.
	var along: float = velocity.dot(dir)
	if along < 0.0:
		velocity -= dir * along * GameManager.air_control
	velocity += dir * GameManager.recoil_strength * GameManager.recoil_multiplier
	reload_lock = GameManager.reload_delay
	if absf(dir.y) > absf(dir.x):
		visual_scale = Vector2(0.72, 1.3)
	else:
		visual_scale = Vector2(1.3, 0.72)

func _on_landed(impact: float) -> void:
	var k: float = clampf(impact / 800.0, 0.2, 1.0)
	visual_scale = Vector2(1.0 + 0.35 * k, 1.0 - 0.35 * k)
	Fx.burst(get_parent(), global_position + Vector2(0, 14), Vector2.UP, Color(0.6, 1.5, 1.9), 8, 180.0, 70.0, 0.3, 2.5)
	Sfx.play("land", 0.1)
	if impact > 500.0:
		camera.add_trauma(0.12)

func die() -> void:
	if not alive or spawn_protect > 0.0:
		return
	alive = false
	set_deferred("collision_layer", 0)
	velocity = Vector2.ZERO
	var level: Node = get_parent()
	Fx.burst(level, global_position, Vector2.UP, Color(0.3, 1.8, 2.2), 30, 380.0, 180.0, 0.7, 4.0)
	Fx.burst(level, global_position, Vector2.UP, Color(2.2, 0.4, 0.8), 14, 260.0, 180.0, 0.6, 3.0)
	camera.add_trauma(0.8)
	Sfx.play("death")
	died.emit()

func respawn(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	alive = true
	spawn_protect = 0.5
	# Kollision erst nach dem Teleport (deferred) wieder aktivieren: so löst der alte Todesort
	# (Spikes) keinen zweiten Tod aus.
	set_deferred("collision_layer", 2)
	ammo = GameManager.max_ammo
	reload_lock = 0.0
	_was_on_floor = true
	visual_scale = Vector2.ONE
	camera.reset_smoothing()

func _process(delta: float) -> void:
	visual_scale = visual_scale.lerp(Vector2.ONE, minf(1.0, delta * 14.0))
	queue_redraw()

func _draw() -> void:
	if not alive:
		return
	var tex: Texture2D = GameArt.get_tex(GameArt.PLAYER)
	if tex != null:
		var flip: float = -1.0 if weapon.aim.x < 0.0 else 1.0
		draw_set_transform(Vector2(0, 14), 0.0, Vector2(visual_scale.x * flip, visual_scale.y))
		var src: Rect2 = GameArt.region(tex, GameArt.PLAYER_REGION)
		var k: float = GameArt.PLAYER_SCALE
		draw_texture_rect_region(tex, Rect2(-src.size.x * 0.5 * k, -GameArt.PLAYER_FEET_Y * k, src.size.x * k, src.size.y * k), src)
	else:
		draw_set_transform(Vector2(0, 14), 0.0, visual_scale)
		draw_rect(Rect2(-10, -28, 20, 28), Color(0.0, 0.05, 0.1))
		draw_rect(Rect2(-10, -28, 20, 28), Color(0.3, 1.6, 2.0), false, 2.0)
		var eye := Vector2(weapon.aim.x * 4.0, -20.0 + weapon.aim.y * 3.0)
		draw_rect(Rect2(eye.x - 3.0, eye.y - 3.0, 6, 6), Color(2.5, 2.5, 2.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Munitions-Pips über dem Kopf
	var n: int = GameManager.max_ammo
	var total: float = n * 7.0 - 2.0
	for i in n:
		var c: Color = Color(2.0, 1.7, 0.4) if i < ammo else Color(0.2, 0.22, 0.3)
		draw_rect(Rect2(-total * 0.5 + i * 7.0, -30, 5, 5), c)
