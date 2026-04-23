extends Node2D

@export var noise_height_texture: NoiseTexture2D
var noise: Noise
var generateWorld = GenerateWorld.new()

# Node refs (set via @onready after scene is ready)
@onready var sprite_manager = $board/SpriteManager
@onready var camera          = $Camera2D
@onready var hud             = $Camera2D/CanvasLayer/HUD

# Tile pixel size in the tilemap (each tile = 16x16 px)
const TILE_PX = 16

func _ready() -> void:
	# ── Seed ──────────────────────────────────────────────────────────────────
	if GameManager.seed == null:
		randomize()
		noise_height_texture.noise.seed = randi()
	else:
		noise_height_texture.noise.seed = int(GameManager.seed)
	noise = noise_height_texture.noise

	# ── Generate visual terrain ───────────────────────────────────────────────
	generateWorld.generateWorld(
		$board/TileMapLayer, noise, GameManager.x, GameManager.y)
	GameManager.registerBoard($board/TileMapLayer)

	# ── Start WSS2 game logic ─────────────────────────────────────────────────
	GameManager.start_game()

	# ── Populate item sprites from the WSS2 GameMap ───────────────────────────
	_spawn_items_from_game_map()

	# ── Connect signals ───────────────────────────────────────────────────────
	GameManager.connect("turn_completed", _on_turn_completed)
	GameManager.connect("game_over", _on_game_over)

	# Initial render
	sprite_manager.place_player(GameManager.playerPosition)
	_center_camera_on_player()
	hud.update_status(GameManager.player)

func _spawn_items_from_game_map() -> void:
	var gmap = GameManager.game_map
	for cx in range(gmap.width):
		for cy in range(gmap.height):
			var cell = gmap.get_cell(cx, cy)
			for item in cell.items:
				sprite_manager.add_item_sprite(Vector2i(cx, cy), item.item_type)

func _process(delta: float) -> void:
	GameManager.tick(delta)
	sprite_manager.place_player(GameManager.playerPosition)
	_center_camera_on_player()

func _on_turn_completed(log: String) -> void:
	# Remove item sprites the player just collected
	var gmap = GameManager.game_map
	var pp   = GameManager.playerPosition
	var cell = gmap.get_cell(pp.x, pp.y)
	# Rebuild sprites for this cell: remove all then re-add surviving items
	sprite_manager.refresh_cell(pp, cell)
	hud.update_status(GameManager.player)
	hud.add_log(log)

func _on_game_over(won: bool, msg: String) -> void:
	hud.show_result(msg, won)

func _center_camera_on_player() -> void:
	var pp = GameManager.playerPosition
	camera.position = Vector2(pp.x * TILE_PX + TILE_PX / 2,
							  pp.y * TILE_PX + TILE_PX / 2)
