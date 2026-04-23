extends Control

# ── Node refs (set in scene) ──────────────────────────────────────
@onready var setup_panel     = $SetupPanel
@onready var game_panel      = $GamePanel
@onready var map_grid        = $GamePanel/MapContainer/MapGrid
@onready var log_label = $GamePanel/HSplit/LogPanel/LogScroll/LogLabel
@onready var status_label    = $GamePanel/StatusBar/StatusLabel
@onready var step_btn        = $GamePanel/Controls/StepBtn
@onready var auto_btn        = $GamePanel/Controls/AutoBtn
@onready var restart_btn     = $GamePanel/Controls/RestartBtn
@onready var width_spin      = $SetupPanel/Form/WidthSpin
@onready var height_spin     = $SetupPanel/Form/HeightSpin
@onready var diff_option     = $SetupPanel/Form/DiffOption
@onready var vision_option   = $SetupPanel/Form/VisionOption
@onready var brain_option    = $SetupPanel/Form/BrainOption
@onready var start_btn       = $SetupPanel/StartBtn
@onready var result_label    = $GamePanel/ResultLabel

# Runtime
var cell_buttons: Array = []
const CELL_SIZE = 38
var log_lines: Array = []
const MAX_LOG = 60

func _ready():
	GameManager.connect("turn_completed", _on_turn_completed)
	GameManager.connect("game_over", _on_game_over)
	start_btn.connect("pressed", _on_start)
	step_btn.connect("pressed", _on_step)
	auto_btn.connect("pressed", _on_auto_toggle)
	restart_btn.connect("pressed", _on_restart)
	setup_panel.visible = true
	game_panel.visible  = false

func _on_start():
	var w    = int(width_spin.value)
	var h    = int(height_spin.value)
	var diff = ["easy","normal","hard"][diff_option.selected]
	var vis  = ["Cautious","Standard","Broad"][vision_option.selected]
	var brn  = ["Survival","Aggressive"][brain_option.selected]

	GameManager.new_game(w, h, diff, vis, brn)
	setup_panel.visible = false
	game_panel.visible  = true
	result_label.visible = false
	log_lines.clear()
	log_label.text = ""
	_build_map_grid()
	_refresh_map()
	status_label.text = GameManager.player.get_status()

func _build_map_grid():
	# Clear existing
	for child in map_grid.get_children():
		child.queue_free()
	cell_buttons.clear()

	var gmap = GameManager.game_map
	map_grid.columns = gmap.width

	for y in range(gmap.height):
		var row = []
		for x in range(gmap.width):
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			btn.flat = true
			btn.focus_mode = Control.FOCUS_NONE
			map_grid.add_child(btn)
			row.append(btn)
		cell_buttons.append(row)

func _refresh_map():
	var gmap   = GameManager.game_map
	var player = GameManager.player

	for y in range(gmap.height):
		for x in range(gmap.width):
			var cell = gmap.get_cell(x, y)
			var td   = cell.get_terrain_data()
			var btn  = cell_buttons[y][x]

			var color = td["color"]
			var label = td["symbol"]

			if cell.items.size() > 0:
				label += "·"

			if player.pos == Vector2i(x, y):
				label = "★"
				color = Color(1, 0.9, 0.1)

			btn.text = label
			var style = StyleBoxFlat.new()
			style.bg_color = color
			style.border_color = Color(0.2, 0.2, 0.2)
			style.set_border_width_all(1)
			style.set_corner_radius_all(2)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)

func _on_turn_completed(log: String):
	log_lines.append(log)
	if log_lines.size() > MAX_LOG:
		log_lines.pop_front()
	log_label.text = "\n".join(log_lines)
	_refresh_map()
	status_label.text = GameManager.player.get_status()

func _on_game_over(won: bool, player: Player):
	GameManager.auto_play = false
	auto_btn.text = "▶ Auto"
	result_label.visible = true
	if won:
		result_label.text = "🏆 " + player.player_name + " crossed the wilderness!"
		result_label.modulate = Color(0.2, 0.9, 0.3)
	else:
		result_label.text = "💀 " + player.player_name + " perished in the wilderness."
		result_label.modulate = Color(0.9, 0.3, 0.2)

func _on_step():
	if GameManager.running:
		GameManager.do_turn()

func _on_auto_toggle():
	GameManager.auto_play = not GameManager.auto_play
	auto_btn.text = "⏸ Pause" if GameManager.auto_play else "▶ Auto"

func _on_restart():
	GameManager.auto_play = false
	auto_btn.text = "▶ Auto"
	setup_panel.visible = true
	game_panel.visible  = false
