# RECOIL RUNNER (Godot 4.3+)

Projekt öffnen: Godot 4.3 (oder neuer) -> "Importieren" -> `project.godot` wählen -> F5.
Beim ersten Öffnen einmal warten, bis Godot die Scripts (class_name) indexiert hat.

## Steuerung
Maus = Zielen · Linke Maustaste = Schießen (Rückstoß = einzige Bewegung) · R = Level neu · ESC = Pause

## Struktur
scenes/main.tscn            Main (Node) [main.gd] + UI (CanvasLayer) [ui_manager.gd]
scenes/player/player.tscn   Player (CharacterBody2D) [player_controller.gd]
                              ├ CollisionShape2D (Rect 20x28)
                              ├ Weapon (Node2D) [weapon.gd]
                              └ Camera (Camera2D) [game_camera.gd]
scenes/levels/level.tscn    Level (Node2D) [level_manager.gd] – baut Fels, Spikes, Checkpoints, Ziel,
                            bewegliche Plattformen (moving_platform.gd) und den Spieler zur Laufzeit
scripts/game_manager.gd     Autoload: alle Tuning-Werte (Rückstoß, Schwerkraft, Shake ...)
scripts/sfx.gd              Autoload: prozedurale Sounds
scripts/music.gd            Autoload: spielt assets/music.mp3 als Loop
scripts/fx.gd               Partikel-Helfer
scripts/level_data.gd       ASCII-Level (editierbar!) – tools/gen_levels.py erzeugt sie ebenfalls

## Tuning (Game Feel)
Pause-Menü: Rückstoß-Multiplikator, Schwerkraft, Screen Shake, Luftkontrolle (live).
Feintuning in scripts/game_manager.gd: recoil_strength, shoot_cooldown, max_speed, ground_friction, max_ammo ...

## Level-Legende
# Fels · ^ v < > Spikes · S Start · G Ziel · C Checkpoint · M / V bewegliche Plattform (horizontal / vertikal)
