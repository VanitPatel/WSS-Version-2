extends Node2D

var inputChecker = InputChecker.new()

# Track which brain/vision button is currently selected
var _selected_brain: String = "Survival"
var _selected_vision: String = "Standard"

func _ready() -> void:
	# Difficulty defaults
	$MenuRow1/EasyHardButtons/ButtonPosition/EasyButton.disabled = true
	GameManager.difficulty = "easy"

	# Brain defaults
	GameManager.brain_type = "Survival"
	_update_brain_buttons("Survival")

	# Vision defaults
	GameManager.vision_type = "Standard"
	_update_vision_buttons("Standard")

# ─── Difficulty ──────────────────────────────────────────────
func _on_easy_button_pressed() -> void:
	GameManager.difficulty = "easy"
	$MenuRow1/EasyHardButtons/ButtonPosition/EasyButton.disabled = true
	$MenuRow1/EasyHardButtons/ButtonPosition/HardButton.disabled = false

func _on_hard_button_pressed() -> void:
	GameManager.difficulty = "hard"
	$MenuRow1/EasyHardButtons/ButtonPosition/EasyButton.disabled = false
	$MenuRow1/EasyHardButtons/ButtonPosition/HardButton.disabled = true

# ─── Brain selection ─────────────────────────────────────────
func _update_brain_buttons(selected: String) -> void:
	_selected_brain = selected
	GameManager.brain_type = selected
	var brains = ["Survival", "Aggressive", "Merchant"]
	for b in brains:
		var btn = $BrainVisionRow/BrainBox/BrainButtons.get_node(b + "BrainButton")
		if btn:
			btn.disabled = (b == selected)

func _on_survival_brain_button_pressed() -> void:
	_update_brain_buttons("Survival")

func _on_aggressive_brain_button_pressed() -> void:
	_update_brain_buttons("Aggressive")

func _on_merchant_brain_button_pressed() -> void:
	_update_brain_buttons("Merchant")

# ─── Vision selection ────────────────────────────────────────
func _update_vision_buttons(selected: String) -> void:
	_selected_vision = selected
	GameManager.vision_type = selected
	var visions = ["Tunnel", "Standard", "Panoramic"]
	for v in visions:
		var btn = $BrainVisionRow/VisionBox/VisionButtons.get_node(v + "VisionButton")
		if btn:
			btn.disabled = (v == selected)

func _on_tunnel_vision_button_pressed() -> void:
	_update_vision_buttons("Tunnel")

func _on_standard_vision_button_pressed() -> void:
	_update_vision_buttons("Standard")

func _on_panoramic_vision_button_pressed() -> void:
	_update_vision_buttons("Panoramic")

# ─── Navigation ──────────────────────────────────────────────
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gameboard.tscn")

# ─── Seed / Map size ─────────────────────────────────────────
func _on_enter_seed_box_text_changed(seedInput: String) -> void:
	if inputChecker.digitChecker(seedInput, $MenuRow1/SeedBoxPosition/EnterSeedBox):
		GameManager.seed = int(seedInput)

func _on_enter_x_text_changed(xInput: String) -> void:
	if inputChecker.digitChecker(xInput, $MenuRow2/MapSizeBox/SetYourMapSize/EnterX):
		GameManager.x = int(xInput)

func _on_enter_y_text_changed(yInput: String) -> void:
	if inputChecker.digitChecker(yInput, $MenuRow2/MapSizeBox/SetYourMapSize/EnterY):
		GameManager.y = int(yInput)

func _on_line_edit_text_changed(new_text): pass
func _on_line_edit_text_submitted(new_text): pass
func _on_enter_seed_box_text_submitted(new_text): pass
func _on_enter_x_text_submitted(new_text): pass
func _on_enter_y_text_submitted(new_text): pass
