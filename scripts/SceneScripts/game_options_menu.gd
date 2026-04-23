extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
# game_options_menu.gd
# Controls the game options / pre-game setup screen.
# Players configure difficulty, brain type, vision type, map seed, and
# map dimensions here before starting a run.
#
# All selections are written directly into the GameManager autoload singleton
# so they are available when GameManager.start_game() is called after the
# gameboard scene loads.
#
# Scene node layout (approximate):
#   MenuRow1/EasyHardButtons   – Easy / Hard difficulty toggle buttons
#   MenuRow1/SeedBoxPosition   – Text field for optional map seed
#   MenuRow2/MapSizeBox        – Text fields for map width (X) and height (Y)
#   BrainVisionRow/BrainBox    – Survival / Aggressive / Merchant brain buttons
#   BrainVisionRow/VisionBox   – Tunnel / Standard / Panoramic vision buttons
#   Back button                – Returns to the main menu
#   Play button                – Loads the gameboard scene and starts the game
# ─────────────────────────────────────────────────────────────────────────────

# Validator used for the seed and map-size number fields
var inputChecker = InputChecker.new()

# Tracks which button is currently "selected" (disabled) in each group
var _selected_brain:  String = "Survival"
var _selected_vision: String = "Standard"

# ─────────────────────────────────────────────────────────────────────────────
# _ready()
# Sets default values in GameManager and visually marks the default buttons
# as disabled (selected) when the menu first appears.
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Default difficulty: Easy (disable the Easy button to show it's selected)
	$MenuRow1/EasyHardButtons/ButtonPosition/EasyButton.disabled = true
	GameManager.difficulty = "easy"

	# Default brain: Survival
	GameManager.brain_type = "Survival"
	_update_brain_buttons("Survival")

	# Default vision: Standard
	GameManager.vision_type = "Standard"
	_update_vision_buttons("Standard")

# ── Difficulty selection ──────────────────────────────────────────────────────
# Only two difficulty presets are exposed in the UI (Easy / Hard).
# "Normal" difficulty exists in GameMap.DIFFICULTY_WEIGHTS but has no button.

func _on_easy_button_pressed() -> void:
	GameManager.difficulty = "easy"
	# Disable Easy (selected) and enable Hard (not selected) for visual feedback
	$MenuRow1/EasyHardButtons/ButtonPosition/EasyButton.disabled = true
	$MenuRow1/EasyHardButtons/ButtonPosition/HardButton.disabled = false

func _on_hard_button_pressed() -> void:
	GameManager.difficulty = "hard"
	$MenuRow1/EasyHardButtons/ButtonPosition/EasyButton.disabled = false
	$MenuRow1/EasyHardButtons/ButtonPosition/HardButton.disabled = true

# ── Brain selection ───────────────────────────────────────────────────────────
# _update_brain_buttons() disables the selected brain's button and enables all
# others, giving a radio-button feel.

func _update_brain_buttons(selected: String) -> void:
	_selected_brain        = selected
	GameManager.brain_type = selected  # Write to GameManager immediately

	# Iterate all three brain buttons and disable only the selected one
	var brains = ["Survival", "Aggressive", "Merchant"]
	for b in brains:
		var btn = $BrainVisionRow/BrainBox/BrainButtons.get_node(b + "BrainButton")
		if btn:
			btn.disabled = (b == selected)  # Selected button appears greyed out

func _on_survival_brain_button_pressed() -> void:
	_update_brain_buttons("Survival")

func _on_aggressive_brain_button_pressed() -> void:
	_update_brain_buttons("Aggressive")

func _on_merchant_brain_button_pressed() -> void:
	_update_brain_buttons("Merchant")

# ── Vision selection ──────────────────────────────────────────────────────────
# Same radio-button pattern as brain selection above.

func _update_vision_buttons(selected: String) -> void:
	_selected_vision         = selected
	GameManager.vision_type  = selected  # Write to GameManager immediately

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

# ── Navigation ────────────────────────────────────────────────────────────────

# Return to the main menu without starting a game
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# Start the game: load the gameboard scene (GameManager.start_game() is called
# from gameboard.gd._ready() after the scene finishes loading)
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gameboard.tscn")

# ── Seed & map size input ─────────────────────────────────────────────────────
# Each field uses InputChecker to reject non-integer text before applying
# the value to GameManager.  If the field is invalid it is cleared automatically.

func _on_enter_seed_box_text_changed(seedInput: String) -> void:
	# Validate that the seed is a whole number, then store it
	if inputChecker.digitChecker(seedInput, $MenuRow1/SeedBoxPosition/EnterSeedBox):
		GameManager.seed = int(seedInput)

func _on_enter_x_text_changed(xInput: String) -> void:
	# Validate map width and store it
	if inputChecker.digitChecker(xInput, $MenuRow2/MapSizeBox/SetYourMapSize/EnterX):
		GameManager.x = int(xInput)

func _on_enter_y_text_changed(yInput: String) -> void:
	# Validate map height and store it
	if inputChecker.digitChecker(yInput, $MenuRow2/MapSizeBox/SetYourMapSize/EnterY):
		GameManager.y = int(yInput)

# ── Stub handlers ─────────────────────────────────────────────────────────────
# These are connected in the scene but require no action; kept to avoid errors.
func _on_line_edit_text_changed(new_text): pass
func _on_line_edit_text_submitted(new_text): pass
func _on_enter_seed_box_text_submitted(new_text): pass
func _on_enter_x_text_submitted(new_text): pass
func _on_enter_y_text_submitted(new_text): pass
