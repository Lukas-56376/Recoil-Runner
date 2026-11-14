class_name UIManager
extends CanvasLayer
## Komplette UI (HUD, Hauptmenü, Pause, Game Over, Victory) – komplett per Code aufgebaut,
## damit keine Node-Pfade in .tscn-Dateien kaputtgehen können.

signal start_game
signal resume_game
signal restart_level
signal to_menu
signal retry_run

const CYAN := Color(0.3, 1.6, 1.9)
const PINK := Color(2.0, 0.4, 1.0)
const YELLOW := Color(1.0, 0.85, 0.2)
const GREY := Color(0.6, 0.65, 0.8)
# Menü-Palette (passt zu Hintergrund und Terrain: Pastell-Himmel, Violett, Rosa)
const INK := Color(0.18, 0.145, 0.28)
const PLUM := Color(0.294, 0.247, 0.431)
const PLUM_LIGHT := Color(0.43, 0.36, 0.62)
const CREAM := Color(1.0, 0.878, 0.769)
const ROSE := Color(0.961, 0.722, 0.659)
const LILAC := Color(0.86, 0.82, 0.96)

var hud: Control
var menu: Control
var pause_menu: Control
var gameover_menu: Control
var victory_menu: Control
var ammo_row: HBoxContainer
var level_label: Label
var cp_label: Label
var time_label: Label
var deaths_label: Label
var toast: Label
var victory_stats: Label
var _pips: Array[ColorRect] = []
var _toast_tween: Tween
var _menu_bg: Control
var _menu_layers: Array = []

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	_build_menu()
	_build_pause()
	_build_gameover()
	_build_victory()
	show_menu()

func _process(delta: float) -> void:
	if menu == null or not menu.visible or _menu_bg == null:
		return
	var sz: Vector2 = _menu_bg.size
	for l in _menu_layers:
		var off: float = fmod(float(l["off"]) + float(l["speed"]) * delta, maxf(sz.x, 1.0))
		l["off"] = off
		var rects: Array = l["rects"]
		(rects[0] as TextureRect).position = Vector2(-off, 0.0)
		(rects[0] as TextureRect).size = sz
		(rects[1] as TextureRect).position = Vector2(sz.x - off, 0.0)
		(rects[1] as TextureRect).size = sz

# ---------------- Öffentliche API ----------------
func _show_only(c: Control) -> void:
	for s in [hud, menu, pause_menu, gameover_menu, victory_menu]:
		(s as Control).visible = false
	if c != null:
		c.visible = true

func show_menu() -> void:
	_show_only(menu)

func show_hud() -> void:
	_show_only(hud)

func show_pause() -> void:
	hud.visible = true
	pause_menu.visible = true

func hide_pause() -> void:
	pause_menu.visible = false

func show_gameover() -> void:
	_show_only(gameover_menu)

func show_victory(deaths: int, time: float) -> void:
	victory_stats.text = "Tode: %d     Zeit: %s" % [deaths, _fmt(time)]
	_show_only(victory_menu)

func toast_msg(text: String) -> void:
	toast.text = text
	toast.modulate.a = 1.0
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.0)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.6)

func update_hud(level_num: int, level_total: int, ammo: int, max_ammo: int, cps_done: int, cps_total: int, time: float, deaths: int, lives: int) -> void:
	level_label.text = "LEVEL %d / %d" % [level_num, level_total]
	time_label.text = _fmt(time)
	deaths_label.visible = lives >= 0
	deaths_label.text = "LEBEN %d" % lives
	if _pips.size() != max_ammo:
		for p in _pips:
			p.queue_free()
		_pips.clear()
		for i in max_ammo:
			var r := ColorRect.new()
			r.custom_minimum_size = Vector2(16, 30)
			ammo_row.add_child(r)
			_pips.append(r)
	for i in _pips.size():
		_pips[i].color = Color(2.0, 1.7, 0.4) if i < ammo else Color(0.18, 0.2, 0.28)

func _fmt(t: float) -> String:
	return "%d:%05.2f" % [floori(t / 60.0), fmod(t, 60.0)]

# ---------------- Aufbau-Helfer ----------------
func _new_screen(dim: float) -> Control:
	var c := Control.new()
	add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if dim > 0.0:
		var r := ColorRect.new()
		r.color = Color(0.01, 0.01, 0.03, dim)
		c.add_child(r)
		r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c

func _center_box(parent: Control) -> VBoxContainer:
	var cc := CenterContainer.new()
	parent.add_child(cc)
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(v)
	return v

func _label(text: String, fs: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	return l

func _spacer(h: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 50)
	b.add_theme_font_size_override("font_size", 22)
	for col in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(col, CREAM)
	for st in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = PLUM_LIGHT if st == "hover" else PLUM
		sb.set_border_width_all(3)
		sb.border_color = ROSE if st == "hover" else CREAM
		sb.set_corner_radius_all(6)
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(cb)
	return b

func _slider_row(parent: Control, title: String, lo: float, hi: float, step: float, value: float, cb: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(row)
	var name_l := _label(title, 18, Color.WHITE)
	name_l.custom_minimum_size = Vector2(150, 0)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(name_l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(240, 28)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(s)
	var val_l := _label("%.2f" % value, 18, YELLOW)
	val_l.custom_minimum_size = Vector2(80, 0)
	row.add_child(val_l)
	s.value_changed.connect(_on_slider.bind(val_l, cb))

func _on_slider(v: float, val_l: Label, cb: Callable) -> void:
	val_l.text = "%.2f" % v
	cb.call(v)

# ---------------- Screens ----------------
func _build_hud() -> void:
	hud = _new_screen(0.0)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 22)
	var v := VBoxContainer.new()
	margin.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var tl := VBoxContainer.new()
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tl)
	level_label = _label("LEVEL 1", 26, CYAN)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tl.add_child(level_label)
	cp_label = _label("", 16, GREY)
	cp_label.visible = false
	cp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tl.add_child(cp_label)
	var tr := VBoxContainer.new()
	top.add_child(tr)
	time_label = _label("0:00.00", 26, Color.WHITE)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr.add_child(time_label)
	deaths_label = _label("TODE 0", 16, PINK)
	deaths_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr.add_child(deaths_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var bottom := HBoxContainer.new()
	v.add_child(bottom)
	ammo_row = HBoxContainer.new()
	ammo_row.add_theme_constant_override("separation", 6)
	ammo_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(ammo_row)
	# Toast (Checkpoint / Level-Meldungen)
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(cc)
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tm := MarginContainer.new()
	tm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tm.add_theme_constant_override("margin_bottom", 320)
	cc.add_child(tm)
	toast = _label("", 40, Color(0.5, 2.0, 0.9))
	toast.modulate.a = 0.0
	tm.add_child(toast)

## Gleiche Parallax-Ebenen wie im Spiel (Himmel, Ferne, Wolken, Nähe), Wolken driften langsam.
func _build_menu_background(parent: Control) -> void:
	_menu_bg = Control.new()
	_menu_bg.clip_contents = true
	_menu_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_menu_bg)
	_menu_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var found: bool = false
	for entry in GameArt.BG_LAYERS:
		var tex: Texture2D = GameArt.get_tex(entry[0])
		if tex == null:
			continue
		found = true
		var rects: Array = []
		for i in 2:
			var tr := TextureRect.new()
			tr.texture = tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_menu_bg.add_child(tr)
			rects.append(tr)
		_menu_layers.append({"rects": rects, "speed": float(entry[1]) * 60.0, "off": 0.0})
	if not found:
		var fb := ColorRect.new()
		fb.color = Color(0.65, 0.69, 0.94)
		fb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_menu_bg.add_child(fb)
		fb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _menu_label(text: String, fs: int, color: Color) -> Label:
	var l := _label(text, fs, color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", maxi(2, fs / 12))
	return l

func _build_menu() -> void:
	menu = _new_screen(0.0)
	_build_menu_background(menu)
	var cc := CenterContainer.new()
	menu.add_child(cc)
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(INK.r, INK.g, INK.b, 0.78)
	psb.set_border_width_all(3)
	psb.border_color = ROSE
	psb.set_corner_radius_all(10)
	psb.set_content_margin_all(34)
	panel.add_theme_stylebox_override("panel", psb)
	cc.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	v.add_child(_menu_label("RECOIL RUNNER", 72, CREAM))
	v.add_child(_spacer(16))
	var start_btn := _button("START", func() -> void: start_game.emit())
	start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(start_btn)
	var hc := CheckButton.new()
	hc.text = "HARDCORE – nur 3 Leben pro Level"
	hc.add_theme_font_size_override("font_size", 18)
	for col in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		hc.add_theme_color_override(col, CREAM)
	hc.toggled.connect(func(on: bool) -> void: GameManager.hardcore = on)
	hc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(hc)
	var quit_btn := _button("BEENDEN", func() -> void: get_tree().quit())
	quit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(quit_btn)

func _build_pause() -> void:
	pause_menu = _new_screen(0.75)
	var v := _center_box(pause_menu)
	v.add_child(_label("PAUSE", 56, CYAN))
	v.add_child(_button("WEITER", func() -> void: resume_game.emit()))
	v.add_child(_button("LEVEL NEU STARTEN", func() -> void: restart_level.emit()))
	v.add_child(_button("HAUPTMENÜ", func() -> void: to_menu.emit()))
	v.add_child(_spacer(10))
	_slider_row(v, "Rückstoß ×", 0.5, 1.5, 0.05, GameManager.recoil_multiplier, func(x: float) -> void: GameManager.recoil_multiplier = x)
	_slider_row(v, "Schwerkraft", 600.0, 2000.0, 50.0, GameManager.gravity, func(x: float) -> void: GameManager.gravity = x)
	_slider_row(v, "Screen Shake ×", 0.0, 2.0, 0.1, GameManager.shake_multiplier, func(x: float) -> void: GameManager.shake_multiplier = x)
	_slider_row(v, "Luftkontrolle", 0.0, 1.0, 0.1, GameManager.air_control, func(x: float) -> void: GameManager.air_control = x)
	_slider_row(v, "Musik", 0.0, 1.0, 0.05, Music.volume, func(x: float) -> void: Music.set_volume(x))

func _build_gameover() -> void:
	gameover_menu = _new_screen(0.85)
	var v := _center_box(gameover_menu)
	v.add_child(_label("GAME OVER", 72, Color(2.2, 0.3, 0.5)))
	v.add_child(_label("Keine Leben mehr.", 20, GREY))
	v.add_child(_spacer(16))
	v.add_child(_button("NOCHMAL VON VORN", func() -> void: retry_run.emit()))
	v.add_child(_button("HAUPTMENÜ", func() -> void: to_menu.emit()))

func _build_victory() -> void:
	victory_menu = _new_screen(0.85)
	var v := _center_box(victory_menu)
	v.add_child(_label("VICTORY", 72, Color(0.5, 2.2, 0.9)))
	v.add_child(_label("Du hast den Rückstoß gemeistert.", 22, Color.WHITE))
	victory_stats = _label("", 24, YELLOW)
	v.add_child(victory_stats)
	v.add_child(_spacer(16))
	v.add_child(_button("NOCHMAL SPIELEN", func() -> void: retry_run.emit()))
	v.add_child(_button("HAUPTMENÜ", func() -> void: to_menu.emit()))
