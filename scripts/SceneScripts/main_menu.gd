extends Node2D

@export var noise_height_texture : NoiseTexture2D
var noise : Noise

var generateWorld = GenerateWorld.new()

func _ready() -> void:
	#create random seed for main menu background
	randomize()
	noise_height_texture.noise.seed = randi()
	noise = noise_height_texture.noise
	generateWorld.generateWorld($background/TileMapLayer, noise, 300, 100)

#Press play button
func _on_play_button_pressed() -> void:
	#change to game options menu scene
	get_tree().change_scene_to_file("res://scenes/game_options_menu.tscn")

#Press settings button
func _on_settings_button_pressed() -> void:
	#hide main menu buttons, show settings menu
	$Camera2D/CanvasLayer/CenterContainer/MainButtons2.visible = false
	$Camera2D/CanvasLayer/CenterContainer/SettingsMenu.visible = true

#Press back button in settings menu
func _on_back_button_pressed() -> void:
	#hide settings options and show main menu buttons
	$Camera2D/CanvasLayer/CenterContainer/MainButtons2.visible = true
	$Camera2D/CanvasLayer/CenterContainer/SettingsMenu.visible = false	

#Press exit button
func _on_exit_button_pressed() -> void:
	#exit game
	get_tree().quit()
