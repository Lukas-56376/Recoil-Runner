extends Node
## Autoload "Sfx": lädt Sounds aus res://assets/sounds/<name>.(ogg|wav|mp3), falls vorhanden.
## Fehlt eine Datei, wird der prozedurale Ersatzsound verwendet (Spiel läuft also immer).
## Namen: shot, land, death, checkpoint, goal, empty, reload
const SOUND_DIR := "res://assets/sounds/"
const EXTENSIONS := ["ogg", "wav", "mp3"]

var _players: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_add("shot", _tone(300.0, 50.0, 0.18, 0.55, 0.9))
	_add("land", _tone(130.0, 50.0, 0.10, 0.3, 0.7))
	_add("death", _tone(320.0, 40.0, 0.45, 0.6, 0.9))
	_add("checkpoint", _tone(500.0, 900.0, 0.25, 0.0, 0.5))
	_add("goal", _tone(400.0, 1200.0, 0.5, 0.0, 0.5))
	_add("empty", _tone(900.0, 700.0, 0.04, 0.0, 0.3))
	_add("reload", _tone(500.0, 750.0, 0.08, 0.0, 0.4))

func _load_file(sfx_name: String) -> AudioStream:
	for ext in EXTENSIONS:
		var path: String = SOUND_DIR + sfx_name + "." + ext
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res is AudioStream:
				return res
	return null

func _add(sfx_name: String, fallback: AudioStream) -> void:
	var stream: AudioStream = _load_file(sfx_name)
	if stream == null:
		stream = fallback
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = -8.0
	add_child(p)
	_players[sfx_name] = p

func play(sfx_name: String, pitch_var: float = 0.0) -> void:
	var p: AudioStreamPlayer = _players.get(sfx_name)
	if p == null:
		return
	p.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	p.play()

func _tone(f0: float, f1: float, dur: float, noise: float, vol: float) -> AudioStreamWAV:
	var rate: int = 22050
	var n: int = int(dur * rate)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var phase: float = 0.0
	for i in n:
		var t: float = float(i) / float(n)
		var f: float = lerpf(f0, f1, t)
		phase += TAU * f / float(rate)
		var s: float = sin(phase) * (1.0 - noise) + randf_range(-1.0, 1.0) * noise
		var env: float = pow(1.0 - t, 2.0)
		bytes.encode_s16(i * 2, int(clampf(s * env * vol, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	return w
