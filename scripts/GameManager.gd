extends Node

signal turn_completed(log: String)
signal game_over(won: bool, msg: String)

# Difficulty / seed / size set by game_options_menu
var difficulty: String = "easy"   # "easy" | "normal" | "hard"
var seed = null
var x: int = 60
var y: int = 40
var vision_type: String = "Standard"   # "Tunnel" | "Standard" | "Panoramic"
var brain_type:  String = "Survival"   # "Survival" | "Aggressive" | "Merchant"

# Runtime state
var game_map: GameMap = null
var player: Player    = null
var turn: int = 0
var running: bool = false
var auto_play: bool = true
var _timer: float = 0.0
const TURN_DELAY: float = 0.12   # seconds between auto-turns

# Legacy fields used by gameboard.gd for sprite positioning
var playerPosition: Vector2i = Vector2i.ZERO
var boardTileMap: TileMapLayer = null  # kept for terrain-type reads (unused now)

func start_game() -> void:
	turn = 0
	running = true
	_timer = 0.0

	# Build WSS2 game map from difficulty
	game_map = GameMap.new()
	game_map.generate(x, y, difficulty)

	# Place player on the west edge, middle row
	var start_y = y / 2
	player = Player.new("Explorer", 50, 50, 50, 0, start_y)
	playerPosition = player.pos

	# Vision
	var v: Vision
	match vision_type:
		"Tunnel":    v = Vision.make_tunnel(game_map)
		"Panoramic": v = Vision.make_panoramic(game_map)
		_:           v = Vision.make_standard(game_map)

	# Brain
	var b: Brain
	match brain_type:
		"Aggressive": b = Brain.make_aggressive(v)
		"Merchant":   b = Brain.make_merchant(v)
		_:            b = Brain.make_survival(v)

	player.setup(v, b)

# Called from gameboard.gd _process every frame
func tick(delta: float) -> void:
	if not running:
		return
	_timer += delta
	if _timer < TURN_DELAY:
		return
	_timer = 0.0
	_do_turn()

func _do_turn() -> void:
	turn += 1
	game_map.reset_turn()
	var log = player.do_turn(game_map)
	playerPosition = player.pos
	emit_signal("turn_completed", "Turn %d: %s" % [turn, log])

	if not player.alive:
		running = false
		emit_signal("game_over", false,
			"💀 %s perished on turn %d." % [player.player_name, turn])
	elif player.pos.x >= game_map.width - 1:
		player.won = true
		running = false
		emit_signal("game_over", true,
			"🏆 %s reached the east edge on turn %d!" % [player.player_name, turn])

# Legacy – kept so old scene scripts don't crash
func registerBoard(tile_map_layer: TileMapLayer) -> void:
	boardTileMap = tile_map_layer

func runPhase() -> void:
	pass  # replaced by tick()
