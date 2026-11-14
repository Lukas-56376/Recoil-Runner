class_name GameArt
extends RefCounted
## Optionale Grafiken aus res://assets/sprites/<name>.(png|webp|jpg).
## Fehlt eine Datei, bleibt der Vektor-Look. Hier unten kannst du die Ausschnitte anpassen.

const DIR := "res://assets/sprites/"
const EXTENSIONS := ["png", "webp", "jpg"]

# Dateinamen (ohne Endung)
const BACKGROUND := "background"   # Hintergrundbild (wird bildschirmfüllend, gedimmt dahinter gezeichnet)
const ROCK := "rock"               # Fels-Tile (wird pro 32x32-Feld gezeichnet)
const SPIKE := "spike"             # Spike-Sprite, Spitze zeigt nach OBEN (wird für <, >, v gedreht)
const PLAYER := "player"           # Spieler-Spritesheet

# Ausschnitte im Bild in Pixeln. Rect2i(0, 0, 0, 0) = ganzes Bild.
const ROCK_REGION := Rect2i(0, 0, 0, 0)
const SPIKE_REGION := Rect2i(0, 0, 0, 0)
const PLAYER_REGION := Rect2i(0, 0, 32, 32)   # Frame im Sheet (Spalte, Zeile * 32): 0,0 = erster Frame
const PLAYER_SCALE := 2.0                      # Figur ~10x14 px im Bild -> ~20x28 im Spiel = Hitbox
const PLAYER_FEET_Y := 23.0                    # y-Position der Füße im 32x32-Frame (Figur steht darauf)

# Parallax-Hintergrund: Ebenen von hinten nach vorne [Dateiname, Scroll-Faktor horizontal]
# Sind die Dateien da, wird er statt "background" verwendet. 0 = steht fest, 1 = bewegt sich wie das Level.
const BG_LAYERS := [["bg_sky", 0.0], ["bg_far", 0.08], ["bg_clouds", 0.2], ["bg_near", 0.4]]
const VIEW_H := 720.0                          # Spielfensterhöhe, Ebenen werden darauf skaliert

const BACKGROUND_DIM := 0.55                   # 1.0 = volle Helligkeit

static var _cache: Dictionary = {}

static func get_tex(tex_name: String) -> Texture2D:
	if _cache.has(tex_name):
		return _cache[tex_name]
	var found: Texture2D = null
	for ext in EXTENSIONS:
		var path: String = DIR + tex_name + "." + ext
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res is Texture2D:
				found = res
				break
	_cache[tex_name] = found
	return found

static func region(tex: Texture2D, r: Rect2i) -> Rect2:
	if r.size == Vector2i.ZERO:
		return Rect2(Vector2.ZERO, tex.get_size())
	return Rect2(r)
