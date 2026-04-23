extends Control

# In-game HUD: status bar at top, scrolling log at bottom, result overlay.
# Parented to Camera2D/CanvasLayer so it stays fixed on screen.

@onready var status_label  = $StatusBar/StatusLabel
@onready var log_label     = $LogPanel/LogScroll/LogLabel
@onready var result_label  = $ResultLabel

var log_lines: Array = []
const MAX_LOG = 40

func update_status(player) -> void:
    if player == null:
        return
    status_label.text = (
        "❤ STR %d/%d    💧 H2O %d/%d    🍖 FOOD %d/%d    🪙 GOLD %d   |   Pos (%d,%d)" % [
            player.current_strength, player.max_strength,
            player.current_water,    player.max_water,
            player.current_food,     player.max_food,
            player.current_gold,
            player.pos.x,            player.pos.y
        ])

func add_log(line: String) -> void:
    log_lines.append(line)
    if log_lines.size() > MAX_LOG:
        log_lines.pop_front()
    log_label.text = "\n".join(log_lines)

func show_result(msg: String, won: bool) -> void:
    result_label.text = msg
    result_label.modulate = Color(0.2, 0.95, 0.3) if won else Color(0.95, 0.3, 0.2)
    result_label.visible = true
