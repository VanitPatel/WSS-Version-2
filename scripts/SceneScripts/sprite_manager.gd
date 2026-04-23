extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
# sprite_manager.gd
# Manages all Sprite2D nodes on the gameboard:
#   • The player sprite (moves every turn to follow the simulation position).
#   • Item sprites (food, water, gold, trader) placed at their tile positions.
#
# Sprites are 32×32 px; tiles are 16×16 px, so sprites are scaled to 0.5×0.5
# to fit exactly within one tile.
#
# Item sprites are stored in a Dictionary keyed by tile position (Vector2i)
# so they can be quickly found and removed when the player collects an item.
# ─────────────────────────────────────────────────────────────────────────────

# How many pixels wide/tall each tile is in world space
const TILE_PX = 16

# Preloaded textures — loaded once at compile time, shared across all sprites
const TEX_PLAYER = preload("res://assets/player.png")
const TEX_TRADER = preload("res://assets/trader.png")
const TEX_FOOD   = preload("res://assets/food.png")
const TEX_WATER  = preload("res://assets/water.png")
const TEX_GOLD   = preload("res://assets/gold.png")

# Scale factor: sprites are 32px but tiles are 16px → scale by 0.5 to match
const SPR_SCALE = Vector2(0.5, 0.5)

var player_sprite: Sprite2D = null   # The single player sprite (created in _ready)
# Maps tile position → Sprite2D for every item currently visible on the map
var item_sprites: Dictionary = {}

# ─────────────────────────────────────────────────────────────────────────────
# _ready()
# Creates the player sprite and adds it to the scene. The sprite starts at
# (0,0) in world space and is repositioned each frame by place_player().
# z_index = 10 puts the player on top of item sprites (z_index = 5).
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	player_sprite          = Sprite2D.new()
	player_sprite.texture  = TEX_PLAYER
	player_sprite.scale    = SPR_SCALE
	player_sprite.z_index  = 10  # Draw above terrain and items
	add_child(player_sprite)

# ─────────────────────────────────────────────────────────────────────────────
# _tile_center(tile_pos) -> Vector2
# Converts a tile grid position to the world-space pixel position of that
# tile's centre.  Used to position all sprites.
# ─────────────────────────────────────────────────────────────────────────────
func _tile_center(tile_pos: Vector2i) -> Vector2:
	return Vector2(
		tile_pos.x * TILE_PX + TILE_PX * 0.5,   # Horizontal centre of tile
		tile_pos.y * TILE_PX + TILE_PX * 0.5    # Vertical   centre of tile
	)

# ─────────────────────────────────────────────────────────────────────────────
# place_player(tile_pos)
# Moves the player sprite to the centre of the given tile.
# Called every frame from gameboard.gd._process().
# ─────────────────────────────────────────────────────────────────────────────
func place_player(tile_pos: Vector2i) -> void:
	if player_sprite:
		player_sprite.position = _tile_center(tile_pos)

# ─────────────────────────────────────────────────────────────────────────────
# add_item_sprite(tile_pos, item_type)
# Creates a sprite for the given item type at the specified tile, unless one
# already exists there (guarded by the has() check to avoid duplicates).
# z_index = 5 places items above terrain but below the player.
# ─────────────────────────────────────────────────────────────────────────────
func add_item_sprite(tile_pos: Vector2i, item_type: int) -> void:
	if item_sprites.has(tile_pos):
		return  # Sprite already exists for this tile; don't add another
	var spr          = Sprite2D.new()
	spr.texture      = _tex(item_type)   # Choose texture by item type
	spr.scale        = SPR_SCALE
	spr.z_index      = 5                 # Draw above terrain, below player
	spr.position     = _tile_center(tile_pos)
	add_child(spr)
	item_sprites[tile_pos] = spr         # Register so it can be removed later

# ─────────────────────────────────────────────────────────────────────────────
# remove_item_sprite(tile_pos)
# Destroys the item sprite at the given tile (if one exists) and removes its
# entry from the dictionary.  queue_free() defers destruction to end of frame.
# ─────────────────────────────────────────────────────────────────────────────
func remove_item_sprite(tile_pos: Vector2i) -> void:
	if item_sprites.has(tile_pos):
		item_sprites[tile_pos].queue_free()   # Schedule sprite for deletion
		item_sprites.erase(tile_pos)          # Remove the dictionary entry

# ─────────────────────────────────────────────────────────────────────────────
# refresh_cell(tile_pos, cell)
# Removes the current sprite for a tile and re-creates sprites for whatever
# items remain on that cell after the player's visit.
# Called by gameboard._on_turn_completed() for the player's current cell.
# ─────────────────────────────────────────────────────────────────────────────
func refresh_cell(tile_pos: Vector2i, cell) -> void:
	remove_item_sprite(tile_pos)   # Always clear first
	if cell == null:
		return
	# Re-add a sprite for each item still remaining on the cell
	for item in cell.items:
		add_item_sprite(tile_pos, item.item_type)

# ─────────────────────────────────────────────────────────────────────────────
# _tex(item_type) -> Texture2D  (private)
# Maps an Item.Type int to the matching preloaded texture.
# Falls back to TEX_FOOD for unknown types.
# ─────────────────────────────────────────────────────────────────────────────
func _tex(item_type: int) -> Texture2D:
	match item_type:
		0: return TEX_FOOD    # Item.Type.FOOD_BONUS
		1: return TEX_WATER   # Item.Type.WATER_BONUS
		2: return TEX_GOLD    # Item.Type.GOLD_BONUS
		3: return TEX_TRADER  # Item.Type.TRADER
	return TEX_FOOD  # Fallback (should not occur with valid item types)
