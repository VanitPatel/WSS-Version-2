extends Node

# ─────────────────────────────────────────────────────────────────────────────
# GameManager.gd  (AutoLoad singleton)
# The central coordinator for a running WSS2 game session.
#
# Responsibilities:
#   • Stores all game-wide settings chosen on the options screen
#     (difficulty, map size, vision type, brain type, seed).
#   • Creates and owns the GameMap, Player, Vision, and Brain objects.
#   • Drives the game loop: advances one "turn" every TURN_DELAY seconds.
#   • Emits signals so the UI (gameboard.gd / hud.gd) can react without
#     being tightly coupled to the simulation code.
#
# Because this script is registered as an AutoLoad in project.godot,
# any other script can reference it as just "GameManager".
# ─────────────────────────────────────────────────────────────────────────────

# ── Signals ──────────────────────────────────────────────────────────────────
# Emitted after every successful turn with a text summary of what happened
signal turn_completed(log: String)
# Emitted when the game ends; `won` is true if the player reached the east edge
signal game_over(won: bool, msg: String)

# ── Settings (written by game_options_menu.gd before start_game() is called) ─
var difficulty: String = "easy"       # "easy" | "normal" | "hard"
var seed = null                        # null = random each run
var x: int = 60                        # Map width  in tiles
var y: int = 40                        # Map height in tiles
var vision_type: String = "Standard"  # "Tunnel" | "Standard" | "Panoramic"
var brain_type:  String = "Survival"  # "Survival" | "Aggressive" | "Merchant"

# ── Runtime state ─────────────────────────────────────────────────────────────
var game_map: GameMap = null   # The procedurally generated map grid
var player: Player    = null   # The simulated player entity
var turn: int = 0              # Current turn number (increments each tick)
var running: bool = false      # False when game is paused or finished
var auto_play: bool = true     # When true the game advances automatically
var _timer: float = 0.0        # Accumulates delta time between turns

# Time in seconds between automatic turn advances
const TURN_DELAY: float = 0.12

# ── Legacy fields (kept so old scene scripts compile without errors) ──────────
var playerPosition: Vector2i = Vector2i.ZERO   # Mirrors player.pos for the sprite layer
var boardTileMap: TileMapLayer = null          # Reference to the visual tilemap (unused by logic)

# ─────────────────────────────────────────────────────────────────────────────
# start_game()
# Called by gameboard.gd after the scene loads.
# Builds the map, places the player, and wires up Vision + Brain.
# ─────────────────────────────────────────────────────────────────────────────
func start_game() -> void:
	turn    = 0
	running = true
	_timer  = 0.0

	# Generate the tile-based game map using the chosen difficulty's terrain weights
	game_map = GameMap.new()
	game_map.generate(x, y, difficulty)

	# Spawn the player at the left (west) edge, vertically centered
	var start_y = y / 2
	# Player(name, max_strength, max_water, max_food, start_x, start_y)
	player = Player.new("Explorer", 50, 50, 50, 0, start_y)
	playerPosition = player.pos

	# ── Create the Vision object (determines what the player can "see") ──────
	var v: Vision
	match vision_type:
		"Tunnel":    v = Vision.make_tunnel(game_map)    # Only sees east/NE/SE
		"Panoramic": v = Vision.make_panoramic(game_map) # Sees all 8 directions
		_:           v = Vision.make_standard(game_map)  # N/S/E/W (default)

	# ── Create the Brain object (determines how the player acts) ─────────────
	var b: Brain
	match brain_type:
		"Aggressive": b = Brain.make_aggressive(v)  # Rush east, ignore resources
		"Merchant":   b = Brain.make_merchant(v)    # Collect gold, trade often
		_:            b = Brain.make_survival(v)    # Balanced resource management

	# Hand the Vision and Brain to the Player so it can use them each turn
	player.setup(v, b)

# ─────────────────────────────────────────────────────────────────────────────
# tick(delta)
# Called every frame from gameboard.gd _process().
# Accumulates elapsed time and fires a turn when the delay has elapsed.
# ─────────────────────────────────────────────────────────────────────────────
func tick(delta: float) -> void:
	if not running:
		return
	if not auto_play:
		return   # Manual/step mode: turns only advance via do_turn()
	_timer += delta
	if _timer < TURN_DELAY:
		return   # Not enough time has passed yet
	_timer = 0.0
	_do_turn()

# ─────────────────────────────────────────────────────────────────────────────
# _do_turn()  (private)
# Advances the simulation by exactly one turn:
#   1. Resets per-turn item flags on the map.
#   2. Asks the player to act (Brain picks a direction, resources are updated).
#   3. Emits turn_completed so the HUD can update.
#   4. Checks win/lose conditions and emits game_over if triggered.
# ─────────────────────────────────────────────────────────────────────────────
func _do_turn() -> void:
	turn += 1
	game_map.reset_turn()                        # Allow repeating items to be collected again
	var log = player.do_turn(game_map)           # Player acts; returns a human-readable log string
	playerPosition = player.pos                  # Sync cached position for the sprite layer

	emit_signal("turn_completed", "Turn %d: %s" % [turn, log])

	# Check lose condition: player ran out of a resource
	if not player.alive:
		running = false
		emit_signal("game_over", false,
			"💀 %s perished on turn %d." % [player.player_name, turn])
	# Check win condition: player reached the right (east) edge of the map
	elif player.pos.x >= game_map.width - 1:
		player.won = true
		running = false
		emit_signal("game_over", true,
			"🏆 %s reached the east edge on turn %d!" % [player.player_name, turn])

# ─────────────────────────────────────────────────────────────────────────────
# Legacy compatibility stubs
# These exist so that older scene scripts referencing them don't crash.
# ─────────────────────────────────────────────────────────────────────────────

# Stores the visual TileMapLayer reference (not used by game logic)
func registerBoard(tile_map_layer: TileMapLayer) -> void:
	boardTileMap = tile_map_layer

# Old phase-based entry point — replaced by tick(); kept to avoid crashes
func runPhase() -> void:
	pass
