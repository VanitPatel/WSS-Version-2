extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
# main_menu.gd
# Controls the main menu scene.
#
# On startup:
#   • Generates a large procedural world (300×100 tiles) as a decorative
#     background using a random seed each time the menu loads.
#   • Provides three buttons: Play, Settings, Exit.
#   • Settings opens an in-menu panel (not a separate scene) that lets the
#     player adjust basic options, then returns to the main buttons via Back.
# ─────────────────────────────────────────────────────────────────────────────

# The NoiseTexture2D resource is assigned in the Inspector; its seed is
# randomised at runtime to make the background world different every visit.
@export var noise_height_texture : NoiseTexture2D
var noise : Noise   # The underlying Noise object (for per-pixel queries)

# World generator that fills the background TileMapLayer
var generateWorld = GenerateWorld.new()

# ─────────────────────────────────────────────────────────────────────────────
# _ready()
# Generates a random background world and displays the main menu.
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Randomise the background world every time the menu loads
	randomize()
	noise_height_texture.noise.seed = randi()
	noise = noise_height_texture.noise
	# Fill the background TileMapLayer (300 wide × 100 tall) with terrain tiles
	generateWorld.generateWorld($background/TileMapLayer, noise, 300, 100)

# ─────────────────────────────────────────────────────────────────────────────
# Button handlers
# ─────────────────────────────────────────────────────────────────────────────

# Play button: navigate to the game options screen so the player can configure
# their run before the gameboard loads
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_options_menu.tscn")

# Settings button: hide the main button group and show the settings panel
# (both are children of the same CanvasLayer, just toggled visible)
func _on_settings_button_pressed() -> void:
	$Camera2D/CanvasLayer/CenterContainer/MainButtons2.visible = false
	$Camera2D/CanvasLayer/CenterContainer/SettingsMenu.visible = true

# Back button (inside settings panel): close settings and restore main buttons
func _on_back_button_pressed() -> void:
	$Camera2D/CanvasLayer/CenterContainer/MainButtons2.visible = true
	$Camera2D/CanvasLayer/CenterContainer/SettingsMenu.visible = false

# Exit button: close the application
func _on_exit_button_pressed() -> void:
	get_tree().quit()
