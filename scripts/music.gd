extends Node
## Autoload "Music": spielt assets/music.mp3 als Endlosschleife (Menü, Spiel und Pause).
## Datei einfach nach res://assets/music.mp3 legen (alternativ assets/sounds/music.mp3 oder .ogg).
const PATHS := [
	"res://assets/music.mp3",
	"res://assets/sounds/music.mp3",
	"res://assets/music.ogg",
	"res://assets/sounds/music.ogg",
]

var volume: float = 0.4
var _player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	add_child(_player)
	var stream: AudioStream = _load_stream()
	if stream == null:
		push_warning("Music: keine Musikdatei gefunden (assets/music.mp3)")
		return
	_player.stream = stream
	_player.finished.connect(_player.play)   # Sicherheitsnetz, falls Loop nicht greift
	set_volume(volume)
	_player.play()

func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	if _player != null:
		_player.volume_db = linear_to_db(maxf(volume, 0.0001))

func _load_stream() -> AudioStream:
	for path in PATHS:
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res is AudioStreamMP3:
				(res as AudioStreamMP3).loop = true
				return res
			if res is AudioStreamOggVorbis:
				(res as AudioStreamOggVorbis).loop = true
				return res
		# Noch nicht importiert (z. B. Editor gerade erst geöffnet): MP3 direkt von der Platte lesen
		if (path as String).ends_with(".mp3") and FileAccess.file_exists(path):
			var mp3 := AudioStreamMP3.new()
			mp3.data = FileAccess.get_file_as_bytes(path)
			mp3.loop = true
			return mp3
	return null
