extends Node
## Root-Szene: Zustandsmaschine (menu / playing / paused / transition / gameover / victory),
## lädt Levels, verbindet UI und Level.

const LEVEL_SCENE := preload("res://scenes/levels/level.tscn")

@onready var ui: UIManager = $UI
var level: LevelManager
var state: String = "menu"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	RenderingServer.set_default_clear_color(Color(0.025, 0.025, 0.06))
	_setup_environment()
	ui.start_game.connect(_start_game)
	ui.resume_game.connect(_resume)
	ui.restart_level.connect(_restart_level)
	ui.to_menu.connect(_to_menu)
	ui.retry_run.connect(_start_game)
	_to_menu()

func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.15
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_ESCAPE:
		if state == "playing":
			_pause()
		elif state == "paused":
			_resume()
	elif event.keycode == KEY_R and state == "playing":
		_restart_level()

func _toggle_fullscreen() -> void:
	var win: Window = get_window()
	if win.mode == Window.MODE_FULLSCREEN or win.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		win.mode = Window.MODE_WINDOWED
	else:
		win.mode = Window.MODE_FULLSCREEN

func _process(_delta: float) -> void:
	if level != null and level.player != null and (state == "playing" or state == "paused" or state == "transition"):
		ui.update_hud(GameManager.current_level + 1, LevelData.LEVELS.size(), level.player.ammo, GameManager.max_ammo, level.cps_done, level.checkpoints.size(), level.time, level.deaths, level.lives)

func _clear_level() -> void:
	if level != null:
		remove_child(level)
		level.queue_free()
		level = null

func _start_game() -> void:
	GameManager.reset_run()
	_load_level(0)

func _load_level(index: int) -> void:
	_clear_level()
	GameManager.current_level = index
	level = LEVEL_SCENE.instantiate() as LevelManager
	level.process_mode = Node.PROCESS_MODE_PAUSABLE   # Main ist ALWAYS -> Level/Spieler müssen bei Pause stehen bleiben
	add_child(level)
	level.setup(index)
	level.checkpoint_reached.connect(func() -> void: ui.toast_msg("CHECKPOINT"))
	level.level_completed.connect(_on_level_completed)
	level.game_over.connect(_on_game_over)
	get_tree().paused = false
	state = "playing"
	ui.show_hud()
	ui.toast_msg("LEVEL %d – %s" % [index + 1, level.level_name])
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)

func _restart_level() -> void:
	_load_level(GameManager.current_level)

func _pause() -> void:
	state = "paused"
	get_tree().paused = true
	ui.show_pause()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _resume() -> void:
	state = "playing"
	get_tree().paused = false
	ui.hide_pause()
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)

func _to_menu() -> void:
	_clear_level()
	get_tree().paused = false
	state = "menu"
	ui.show_menu()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_level_completed() -> void:
	state = "transition"
	GameManager.total_time += level.time
	ui.toast_msg("LEVEL GESCHAFFT!")
	await get_tree().create_timer(1.2).timeout
	if state != "transition":
		return
	var next: int = GameManager.current_level + 1
	if next >= LevelData.LEVELS.size():
		state = "victory"
		get_tree().paused = true
		ui.show_victory(GameManager.total_deaths, GameManager.total_time)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	else:
		_load_level(next)

func _on_game_over() -> void:
	state = "gameover"
	get_tree().paused = true
	ui.show_gameover()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
