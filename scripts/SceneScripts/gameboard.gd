extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
# gameboard.gd
# The main gameplay scene controller.
# Bridges the visual Godot scene with the WSS2 simulation engine.
#
# Responsibilities:
#   1. Seed and generate the visual tilemap via GenerateWorld.
#   2. Kick off the simulation via GameManager.start_game().
#   3. Spawn item sprites on the map from the simulation's GameMap data.
#   4. Each frame, advance the simulation via GameManager.tick(delta).
#   5. Update the player sprite position and keep the camera centred on it.
#   6. On each completed turn, refresh the HUD and any collected item sprites.
#   7. On game over, show the win/lose result in the HUD.
# ─────────────────────────────────────────────────────────────────────────────

# Inspector-exposed noise texture; its seed is set at runtime
@export var noise_height_texture: NoiseTexture2D

var noise: Noise                           # The actual Noise object extracted from the texture
var generateWorld = GenerateWorld.new()    # Utility object that fills the TileMapLayer

# Scene node references resolved after the scene is ready
@onready var sprite_manager = $board/SpriteManager           # Manages player and item sprites
@onready var camera          = $Camera2D                     # Follows the player
@onready var hud             = $Camera2D/CanvasLayer/HUD     # Heads-up display overlay

# Each visual tile is 16×16 pixels; used to convert grid (tile) coords to world pixels
const TILE_PX = 16

# ─────────────────────────────────────────────────────────────────────────────
# _ready()
# Called once when the scene finishes loading.
# Sets up the noise seed, generates the visual world, starts the simulation,
# populates item sprites, and connects GameManager signals.
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# ── 1. Seed ───────────────────────────────────────────────────────────────
	# Use the seed from the options menu, or a random one if none was set
	if GameManager.seed == null:
		randomize()
		noise_height_texture.noise.seed = randi()
	else:
		noise_height_texture.noise.seed = int(GameManager.seed)
	noise = noise_height_texture.noise

	# ── 2. Generate visual terrain ────────────────────────────────────────────
	# Fills the TileMapLayer children with noise-based terrain tiles
	generateWorld.generateWorld(
		$board/TileMapLayer, noise, GameManager.x, GameManager.y)
	GameManager.registerBoard($board/TileMapLayer)  # Keeps legacy reference in GameManager

	# ── 3. Start the WSS2 game logic ──────────────────────────────────────────
	# Creates GameMap, Player, Vision, and Brain; sets running = true
	GameManager.start_game()

	# ── 4. Spawn item sprites from simulation data ─────────────────────────────
	# The GameMap already has all items placed; create visible sprites for them
	_spawn_items_from_game_map()

	# ── 5. Connect GameManager signals ────────────────────────────────────────
	GameManager.connect("turn_completed", _on_turn_completed)
	GameManager.connect("game_over",      _on_game_over)

	# ── 6. Initial render ─────────────────────────────────────────────────────
	sprite_manager.place_player(GameManager.playerPosition)  # Draw player sprite
	_center_camera_on_player()                               # Frame the camera
	hud.update_status(GameManager.player)                    # Show initial stats

# ─────────────────────────────────────────────────────────────────────────────
# _spawn_items_from_game_map()
# Reads every cell in the simulation GameMap and creates a sprite for each
# item found.  Called once at startup; thereafter gameboard refreshes cells
# individually as items are collected.
# ─────────────────────────────────────────────────────────────────────────────
func _spawn_items_from_game_map() -> void:
	var gmap = GameManager.game_map
	for cx in range(gmap.width):
		for cy in range(gmap.height):
			var cell = gmap.get_cell(cx, cy)
			for item in cell.items:
				# add_item_sprite won't add a second sprite if one already exists
				sprite_manager.add_item_sprite(Vector2i(cx, cy), item.item_type)

# ─────────────────────────────────────────────────────────────────────────────
# _process(delta)
# Called every frame. Advances the simulation timer and moves the player sprite.
# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	# Advance the simulation (may or may not fire a turn depending on timing)
	GameManager.tick(delta)
	# Keep the player sprite and camera in sync with the simulation position
	sprite_manager.place_player(GameManager.playerPosition)
	_center_camera_on_player()

# ─────────────────────────────────────────────────────────────────────────────
# _on_turn_completed(log)
# Received from GameManager after each successful game turn.
# Refreshes the item sprites on the player's current cell (some may have been
# collected) and updates the HUD status and log.
# ─────────────────────────────────────────────────────────────────────────────
func _on_turn_completed(log: String) -> void:
	var gmap = GameManager.game_map
	var pp   = GameManager.playerPosition          # Player's current tile position
	var cell = gmap.get_cell(pp.x, pp.y)
	# Rebuild sprites for this cell: removes old sprite, then re-adds any that remain
	sprite_manager.refresh_cell(pp, cell)
	hud.update_status(GameManager.player)          # Refresh the stat bar
	hud.add_log(log)                               # Append the turn log entry

# ─────────────────────────────────────────────────────────────────────────────
# _on_game_over(won, msg)
# Received from GameManager when the player wins or dies.
# Passes the message to the HUD to display a result overlay.
# ─────────────────────────────────────────────────────────────────────────────
func _on_game_over(won: bool, msg: String) -> void:
	hud.show_result(msg, won)

# ─────────────────────────────────────────────────────────────────────────────
# _center_camera_on_player()
# Moves the Camera2D so the player sprite is always in the centre of the screen.
# Converts the tile grid position to world pixel coordinates by multiplying by
# TILE_PX and adding a half-tile offset to land on the sprite's centre.
# ─────────────────────────────────────────────────────────────────────────────
func _center_camera_on_player() -> void:
	var pp = GameManager.playerPosition
	camera.position = Vector2(
		pp.x * TILE_PX + TILE_PX / 2,   # Horizontal centre of the tile
		pp.y * TILE_PX + TILE_PX / 2    # Vertical   centre of the tile
	)
