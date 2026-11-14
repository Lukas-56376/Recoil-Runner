extends Node
## Autoload "GameManager": globale Einstellungen + Run-Status.
## Alle Werte sind live veränderbar (siehe Pause-Menü) und werden vom Spieler jeden Frame gelesen.

# --- Rückstoß / Physik (HERZSTÜCK: hier tunen!) ---
var recoil_strength: float = 540.0      # Impuls pro Schuss (px/s)
var recoil_multiplier: float = 1.0      # globaler Multiplikator
var gravity: float = 1200.0
var fall_gravity_mult: float = 1.15     # etwas schnelleres Fallen = knackigeres Gefühl
var max_speed: float = 900.0
var shoot_cooldown: float = 0.16        # Schussgeschwindigkeit (s zwischen Schüssen)
var ground_friction: float = 3000.0
var air_drag: float = 40.0
var air_control: float = 1.0            # 0..1: wie stark entgegengesetztes Momentum beim Schuss gelöscht wird
var max_ammo: int = 6
var reload_delay: float = 0.15

# --- Feedback ---
var shake_multiplier: float = 1.0

# --- Run-Status ---
var hardcore: bool = false
var current_level: int = 0
var total_deaths: int = 0
var total_time: float = 0.0

func reset_run() -> void:
	current_level = 0
	total_deaths = 0
	total_time = 0.0
