class_name TerrainArt
extends RefCounted
## Zeichnet Plattformen und Spikes als Pixel-Art im Stil des Hintergrunds (Lila/Rosa-Töne).
## Alles wird EINMAL in eine Textur gebacken (16x16 Pixel pro 32x32-Feld, 2-fach hochskaliert).

const PX: int = 2          # Weltpixel pro Bildpixel
const N: int = 16          # Bildpixel pro Tile

const OUTLINE := Color(0.180, 0.145, 0.282)
const BODY0 := Color(0.294, 0.247, 0.431)
const BODY1 := Color(0.329, 0.278, 0.478)
const BODY2 := Color(0.247, 0.204, 0.373)
const SPECK := Color(0.431, 0.373, 0.600)
const CAP_HI := Color(0.925, 0.784, 0.949)
const CAP_MID := Color(0.788, 0.627, 0.886)
const CAP_LOW := Color(0.604, 0.502, 0.776)
const SP_LIT := Color(0.976, 0.667, 0.725)
const SP_SHADE := Color(0.780, 0.373, 0.502)
const SP_TIP := Color(1.000, 0.890, 0.890)
const SP_OUT := Color(0.361, 0.165, 0.333)
const W_OUT := Color(0.231, 0.145, 0.251)
const W_BODY0 := Color(0.478, 0.329, 0.471)
const W_BODY1 := Color(0.525, 0.376, 0.541)
const W_BODY2 := Color(0.400, 0.263, 0.416)
const W_CAP_HI := Color(1.000, 0.878, 0.769)
const W_CAP_MID := Color(0.961, 0.722, 0.659)
const W_CAP_LOW := Color(0.788, 0.541, 0.596)

static func _h(x: int, y: int) -> float:
	var n: int = (x * 73856093) ^ (y * 19349663)
	n = (n ^ (n >> 13)) * 1274126177
	return float(n & 0xFFFF) / 65535.0

static func build_texture(lv: LevelManager, rocks: bool, spikes: bool) -> ImageTexture:
	var img := Image.create_empty(lv.width_tiles * N, lv.height_tiles * N, false, Image.FORMAT_RGBA8)
	for gy in lv.height_tiles:
		for gx in lv.width_tiles:
			var c: String = lv.cell_at(gx, gy)
			if rocks and c == "#":
				_rock_cell(img, lv, gx, gy)
			elif spikes and (c == "^" or c == "v" or c == "<" or c == ">"):
				_spike_cell(img, gx, gy, c)
	return ImageTexture.create_from_image(img)

static func _rock_cell(img: Image, lv: LevelManager, gx: int, gy: int) -> void:
	var up: bool = lv.cell_at(gx, gy - 1) == "#"
	var dn: bool = lv.cell_at(gx, gy + 1) == "#"
	var lf: bool = lv.cell_at(gx - 1, gy) == "#"
	var rt: bool = lv.cell_at(gx + 1, gy) == "#"
	var ox: int = gx * N
	var oy: int = gy * N
	for py in N:
		for px in N:
			var n: float = _h(gx * 4 + (px >> 2), gy * 4 + (py >> 2))
			var col: Color = BODY0
			if n < 0.16:
				col = BODY2
			elif n < 0.34:
				col = BODY1
			if _h(gx * N + px, gy * N + py) > 0.975:
				col = SPECK
			if not up:
				var t: int = 5 + (1 if _h(gx * N + px, gy + 777) < 0.4 else 0) + (2 if _h(gx * N + px, gy + 999) < 0.12 else 0)
				if py < t:
					col = CAP_HI if py == 0 else (CAP_MID if py < t - 2 else CAP_LOW)
			if not dn and py == N - 2:
				col = BODY2
			if not lf and px == 1 and (up or py > 4):
				col = BODY2
			if (not lf and px == 0) or (not rt and px == N - 1) or (not dn and py == N - 1):
				col = OUTLINE
			img.set_pixel(ox + px, oy + py, col)

# Spike nach OBEN in 16x16 (zwei Zacken). Transparent = Color(0,0,0,0).
static func _spike_px(x: int, y: int) -> Color:
	if y < 4:
		return Color(0, 0, 0, 0)
	for s in 2:
		var cx: float = 4.0 + 8.0 * s
		var half: float = 0.6 + float(y - 4) / 11.0 * 3.4
		var dx: float = float(x) + 0.5 - cx
		if absf(dx) <= half:
			if y == 15 or (absf(dx) > half - 1.0 and y > 5):
				return SP_OUT
			if y <= 5:
				return SP_TIP
			return SP_LIT if dx < 0.0 else SP_SHADE
	return Color(0, 0, 0, 0)

static func _spike_cell(img: Image, gx: int, gy: int, c: String) -> void:
	var ox: int = gx * N
	var oy: int = gy * N
	var m: int = N - 1
	for y in N:
		for x in N:
			var sx: int = x
			var sy: int = y
			match c:
				"v":
					sy = m - y
				">":
					sx = y
					sy = m - x
				"<":
					sx = m - y
					sy = x
			var col: Color = _spike_px(sx, sy)
			if col.a > 0.0:
				img.set_pixel(ox + x, oy + y, col)

## Bewegliche Plattform (warme Rosa/Pfirsich-Töne, damit man sie von festem Fels unterscheidet).
static func draw_platform(ci: CanvasItem, r: Rect2) -> void:
	var bw: int = int(r.size.x) / PX
	var bh: int = int(r.size.y) / PX
	for by in bh:
		for bx in bw:
			var n: float = _h(bx, by + 50)
			var col: Color = W_BODY0
			if n < 0.15:
				col = W_BODY2
			elif n < 0.32:
				col = W_BODY1
			if by == 0:
				col = W_CAP_HI
			elif by == 1:
				col = W_CAP_MID
			elif by == 2:
				col = W_CAP_LOW
			if bx == 0 or bx == bw - 1 or by == bh - 1:
				col = W_OUT
			ci.draw_rect(Rect2(r.position + Vector2(bx * PX, by * PX), Vector2(PX, PX)), col)
