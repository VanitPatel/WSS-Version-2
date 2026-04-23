extends Control

# ─────────────────────────────────────────────────────────────────────────────
# hud.gd
# In-game Heads-Up Display (HUD).
# Parented to Camera2D/CanvasLayer so it stays fixed on screen regardless of
# where the camera scrolls.
#
# Three UI sections:
#   StatusBar  – one-line stat strip at the top showing all player resources
#   LogPanel   – scrolling text area at the bottom showing recent turn events
#   ResultLabel – large centred label revealed when the game ends (win/lose)
# ─────────────────────────────────────────────────────────────────────────────

# Node references resolved after scene ready
@onready var status_label  = $StatusBar/StatusLabel     # Top stat strip
@onready var log_label     = $LogPanel/LogScroll/LogLabel  # Scrollable turn log
@onready var result_label  = $ResultLabel               # Game-over overlay (hidden until game ends)

var log_lines: Array = []   # Rolling buffer of log text lines
const MAX_LOG = 40           # Maximum lines kept in the buffer before oldest are dropped

# ─────────────────────────────────────────────────────────────────────────────
# update_status(player)
# Refreshes the top status bar with the player's current resource levels.
# Called by gameboard.gd every turn and on initial scene ready.
# ─────────────────────────────────────────────────────────────────────────────
func update_status(player) -> void:
    if player == null:
        return  # Defensive check; player might not be initialised yet
    # Build a formatted status string with emoji icons for each resource
    status_label.text = (
        "❤ STR %d/%d    💧 H2O %d/%d    🍖 FOOD %d/%d    🪙 GOLD %d   |   Pos (%d,%d)" % [
            player.current_strength, player.max_strength,
            player.current_water,    player.max_water,
            player.current_food,     player.max_food,
            player.current_gold,
            player.pos.x,            player.pos.y
        ])

# ─────────────────────────────────────────────────────────────────────────────
# add_log(line)
# Appends a new turn-log line to the scrolling log panel.
# When the buffer exceeds MAX_LOG entries the oldest line is dropped (FIFO).
# ─────────────────────────────────────────────────────────────────────────────
func add_log(line: String) -> void:
    log_lines.append(line)
    if log_lines.size() > MAX_LOG:
        log_lines.pop_front()  # Remove the oldest entry to cap the buffer
    log_label.text = "\n".join(log_lines)  # Rebuild the full log text

# ─────────────────────────────────────────────────────────────────────────────
# show_result(msg, won)
# Reveals the result overlay when the game ends.
# Green text for a win; red text for a loss.
# ─────────────────────────────────────────────────────────────────────────────
func show_result(msg: String, won: bool) -> void:
    result_label.text     = msg
    # Use a vivid green for victory or vivid red for defeat
    result_label.modulate = Color(0.2, 0.95, 0.3) if won else Color(0.95, 0.3, 0.2)
    result_label.visible  = true
