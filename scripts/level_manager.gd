class_name LevelManager
extends Node2D
## Baut ein Level zur Laufzeit aus den ASCII-Karten in level_data.gd.
## Legende: # Fels | ^ v < > Spikes (Spitze zeigt in Pfeilrichtung) | S Start | G Ziel (links unten, 2x3)
##          C Checkpoint | M horizontale / V vertikale bewegliche Plattform

signal checkpoint_reached
signal level_completed
signal game_over

const TILE: int = 32
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var level_name: String = ""
var rows: Array = []
var width_tiles: int = 0
var height_tiles: int = 0
var player: Player
var spawn_pos: Vector2 = Vector2.ZERO
var checkpoint_pos: Vector2 = Vector2.ZERO
var checkpoints: Array[Dictionary] = []
var cps_done: int = 0
var solid_rects: Array[Rect2] = []
var spikes: Array[Dictionary] = []
var goal_rect: Rect2 = Rect2()
var time: float = 0.0
var deaths: int = 0
var lives: int = -1
var running: bool = true
var _respawn_pending: bool = false
var _pulse: float = 0.0
var _has_bg: bool = false

func setup(index: int) -> void:
	var data: Dictionary = LevelData.LEVELS[index]
	level_name = data["name"]
	rows = data["rows"]
	height_tiles = rows.size()
	for r in rows:
		width_tiles = maxi(width_tiles, (r as String).length())
	lives = 3 if GameManager.hardcore else -1
	_parse()
	_build_solids()
	_spawn_player()
	_add_background()
	_add_terrain()

func cell_at(x: int, y: int) -> String:
	if y < 0 or y >= height_tiles or x < 0:
		return "."
	return _at(x, y)

func _add_terrain() -> void:
	var rocks: bool = GameArt.get_tex(GameArt.ROCK) == null
	var spk: bool = GameArt.get_tex(GameArt.SPIKE) == null
	if not rocks and not spk:
		return
	var sp := Sprite2D.new()
	sp.texture = TerrainArt.build_texture(self, rocks, spk)
	sp.centered = false
	sp.scale = Vector2(TerrainArt.PX, TerrainArt.PX)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index = -1
	add_child(sp)

func _add_parallax_background() -> void:
	var pb := ParallaxBackground.new()
	pb.layer = -10
	for entry in GameArt.BG_LAYERS:
		var tex: Texture2D = GameArt.get_tex(entry[0])
		if tex == null:
			continue
		var k: float = GameArt.VIEW_H / tex.get_size().y
		var pl := ParallaxLayer.new()
		pl.motion_scale = Vector2(entry[1], 0.0)
		pl.motion_mirroring = Vector2(tex.get_size().x * k, 0.0)
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		sp.scale = Vector2(k, k)
		pl.add_child(sp)
		pb.add_child(pl)
	add_child(pb)

func _add_background() -> void:
	if GameArt.get_tex(GameArt.BG_LAYERS[0][0]) != null:
		_has_bg = true
		_add_parallax_background()
		return
	var tex: Texture2D = GameArt.get_tex(GameArt.BACKGROUND)
	if tex == null:
		return
	_has_bg = true
	var layer := CanvasLayer.new()
	layer.layer = -10
	var tr := TextureRect.new()
	tr.texture = tex
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.modulate = Color(1, 1, 1, GameArt.BACKGROUND_DIM)
	layer.add_child(tr)
	add_child(layer)

func _at(x: int, y: int) -> String:
	var row: String = rows[y]
	if x >= row.length():
		return "."
	return row[x]

func _cell_spawn(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + 16, (y + 1) * TILE - 14)

func _parse() -> void:
	for y in height_tiles:
		for x in width_tiles:
			var c: String = _at(x, y)
			match c:
				"^", "v", "<", ">":
					_add_spike(x, y, c)
				"S":
					spawn_pos = _cell_spawn(x, y)
				"G":
					goal_rect = Rect2(x * TILE, (y - 2) * TILE, TILE * 2, TILE * 3)
					_make_area(goal_rect, _on_goal)
				"C":
					var idx: int = checkpoints.size()
					checkpoints.append({"cell": Vector2(x * TILE, y * TILE), "spawn": _cell_spawn(x, y), "active": false})
					_make_area(Rect2(x * TILE + 4, y * TILE - TILE, 24, TILE * 2), _on_checkpoint.bind(idx))
				"M", "V":
					var mp := MovingPlatform.new()
					add_child(mp)
					mp.setup(Vector2(x * TILE + 16, y * TILE + 8), c == "V", float(x) * 0.7)
	checkpoint_pos = spawn_pos

func _build_solids() -> void:
	# Horizontale Läufe zu Rechtecken, dann vertikal verschmelzen (weniger Shapes, keine Nähte).
	var open: Dictionary = {}
	for y in height_tiles:
		var next_open: Dictionary = {}
		var x: int = 0
		while x < width_tiles:
			if _at(x, y) == "#":
				var x0: int = x
				while x < width_tiles and _at(x, y) == "#":
					x += 1
				var key: String = "%d:%d" % [x0, x]
				if open.has(key):
					var idx: int = open[key]
					var rr: Rect2 = solid_rects[idx]
					rr.size.y += TILE
					solid_rects[idx] = rr
					next_open[key] = idx
				else:
					solid_rects.append(Rect2(x0 * TILE, y * TILE, (x - x0) * TILE, TILE))
					next_open[key] = solid_rects.size() - 1
			else:
				x += 1
		open = next_open
	for r in solid_rects:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = r.position + r.size * 0.5
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		cs.shape = shape
		body.add_child(cs)
		add_child(body)

func _add_spike(x: int, y: int, c: String) -> void:
	var cell := Vector2(x * TILE, y * TILE)
	var hit: Rect2
	match c:
		"^": hit = Rect2(cell + Vector2(6, 14), Vector2(20, 18))
		"v": hit = Rect2(cell + Vector2(6, 0), Vector2(20, 18))
		"<": hit = Rect2(cell + Vector2(14, 6), Vector2(18, 20))
		_: hit = Rect2(cell + Vector2(0, 6), Vector2(18, 20))
	_make_area(hit, _on_hazard)
	spikes.append({"cell": cell, "c": c})

func _make_area(r: Rect2, cb: Callable) -> Area2D:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.monitorable = false
	a.position = r.position + r.size * 0.5
	var cs := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = r.size
	cs.shape = s
	a.add_child(cs)
	add_child(a)
	a.body_entered.connect(cb)
	return a

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	add_child(player)
	player.global_position = spawn_pos
	player.camera.set_bounds(width_tiles * TILE, height_tiles * TILE)
	player.camera.reset_smoothing()
	player.died.connect(_on_player_died)

# ---------------- Callbacks ----------------
func _on_hazard(body: Node2D) -> void:
	if body is Player:
		(body as Player).die()

func _on_checkpoint(body: Node2D, idx: int) -> void:
	if not (body is Player) or checkpoints[idx]["active"]:
		return
	checkpoints[idx]["active"] = true
	checkpoint_pos = checkpoints[idx]["spawn"]
	cps_done += 1
	Sfx.play("checkpoint")
	Fx.burst(self, checkpoints[idx]["cell"] + Vector2(16, 0), Vector2.UP, Color(0.4, 2.2, 0.8), 18, 260.0, 60.0, 0.6, 3.0)
	player.camera.add_trauma(0.15)
	checkpoint_reached.emit()

func _on_goal(body: Node2D) -> void:
	if not (body is Player) or not running:
		return
	running = false
	player.set_physics_process(false)
	Sfx.play("goal")
	Fx.burst(self, goal_rect.get_center(), Vector2.UP, Color(0.4, 2.2, 0.9), 40, 420.0, 180.0, 0.9, 4.0)
	player.camera.add_trauma(0.4)
	level_completed.emit()

func _on_player_died() -> void:
	if _respawn_pending:
		return
	_respawn_pending = true
	deaths += 1
	GameManager.total_deaths += 1
	if lives >= 0:
		lives -= 1
		if lives <= 0:
			game_over.emit()
			return
	get_tree().create_timer(0.6, false).timeout.connect(_respawn)

func _respawn() -> void:
	_respawn_pending = false
	if running and is_instance_valid(player):
		player.respawn(checkpoint_pos)

func _process(delta: float) -> void:
	_pulse += delta
	if running and player != null and player.alive:
		time += delta
		if player.global_position.y > height_tiles * TILE + 120:
			player.die()
	queue_redraw()

# ---------------- Rendering ----------------
func _xf(p: Vector2, c: String) -> Vector2:
	match c:
		"v": return Vector2(p.x, 32.0 - p.y)
		">": return Vector2(32.0 - p.y, p.x)
		"<": return Vector2(p.y, p.x)
	return p

func _draw() -> void:
	if not _has_bg:
		var w: float = width_tiles * TILE
		var h: float = height_tiles * TILE
		for gx in range(0, int(w) + 1, 128):
			draw_line(Vector2(gx, 0), Vector2(gx, h), Color(0.1, 0.15, 0.32, 0.25))
		for gy in range(0, int(h) + 1, 128):
			draw_line(Vector2(0, gy), Vector2(w, gy), Color(0.1, 0.15, 0.32, 0.25))
	# Eigene Grafiken (rock.png / spike.png) haben Vorrang; sonst kommt TerrainArt (siehe _add_terrain).
	var rock_tex: Texture2D = GameArt.get_tex(GameArt.ROCK)
	if rock_tex != null:
		var src: Rect2 = GameArt.region(rock_tex, GameArt.ROCK_REGION)
		for r in solid_rects:
			for cy in range(int(r.size.y) / TILE):
				for cx in range(int(r.size.x) / TILE):
					draw_texture_rect_region(rock_tex, Rect2(r.position + Vector2(cx * TILE, cy * TILE), Vector2(TILE, TILE)), src)
	var spike_tex: Texture2D = GameArt.get_tex(GameArt.SPIKE)
	if spike_tex != null:
		for s in spikes:
			var cell: Vector2 = s["cell"]
			var ang: float = {"^": 0.0, ">": PI * 0.5, "v": PI, "<": -PI * 0.5}[s["c"]]
			draw_set_transform(cell + Vector2(16, 16), ang, Vector2.ONE)
			draw_texture_rect_region(spike_tex, Rect2(-16, -16, 32, 32), GameArt.region(spike_tex, GameArt.SPIKE_REGION))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for cp in checkpoints:
		var cell: Vector2 = cp["cell"]
		var col: Color = Color(0.4, 2.0, 0.7) if cp["active"] else Color(0.4, 0.5, 0.8)
		draw_line(cell + Vector2(16, 32), cell + Vector2(16, -28), col, 3.0)
		draw_colored_polygon(PackedVector2Array([cell + Vector2(16, -28), cell + Vector2(34, -20), cell + Vector2(16, -12)]), col)
	if goal_rect.size != Vector2.ZERO:
		var a: float = 0.5 + 0.5 * sin(_pulse * 4.0)
		draw_rect(goal_rect, Color(0.2, 2.0, 0.6, 0.12 + 0.15 * a))
		draw_rect(goal_rect, Color(0.3, 2.2, 0.8), false, 3.0)
		draw_string(ThemeDB.fallback_font, goal_rect.position + Vector2(0, 20), "ZIEL", HORIZONTAL_ALIGNMENT_CENTER, goal_rect.size.x, 16, Color(0.5, 2.0, 0.9))
