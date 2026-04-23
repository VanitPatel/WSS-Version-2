extends Node2D

const TILE_PX = 16

const TEX_PLAYER = preload("res://assets/player.png")
const TEX_TRADER = preload("res://assets/trader.png")
const TEX_FOOD   = preload("res://assets/food.png")
const TEX_WATER  = preload("res://assets/water.png")
const TEX_GOLD   = preload("res://assets/gold.png")

# Sprites are 32x32, tiles are 16x16 → scale to fit exactly in one tile
const SPR_SCALE = Vector2(0.5, 0.5)

var player_sprite: Sprite2D = null
# tile_pos (Vector2i) -> Sprite2D
var item_sprites: Dictionary = {}

func _ready() -> void:
	player_sprite = Sprite2D.new()
	player_sprite.texture = TEX_PLAYER
	player_sprite.scale   = SPR_SCALE
	player_sprite.z_index = 10
	add_child(player_sprite)

func _tile_center(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * TILE_PX + TILE_PX * 0.5,
				   tile_pos.y * TILE_PX + TILE_PX * 0.5)

func place_player(tile_pos: Vector2i) -> void:
	if player_sprite:
		player_sprite.position = _tile_center(tile_pos)

func add_item_sprite(tile_pos: Vector2i, item_type: int) -> void:
	if item_sprites.has(tile_pos):
		return
	var spr = Sprite2D.new()
	spr.texture  = _tex(item_type)
	spr.scale    = SPR_SCALE
	spr.z_index  = 5
	spr.position = _tile_center(tile_pos)
	add_child(spr)
	item_sprites[tile_pos] = spr

func remove_item_sprite(tile_pos: Vector2i) -> void:
	if item_sprites.has(tile_pos):
		item_sprites[tile_pos].queue_free()
		item_sprites.erase(tile_pos)

# Refresh a cell: remove existing sprite then re-add for each remaining item
func refresh_cell(tile_pos: Vector2i, cell) -> void:
	remove_item_sprite(tile_pos)
	if cell == null:
		return
	for item in cell.items:
		add_item_sprite(tile_pos, item.item_type)

func _tex(item_type: int) -> Texture2D:
	match item_type:
		0: return TEX_FOOD
		1: return TEX_WATER
		2: return TEX_GOLD
		3: return TEX_TRADER
	return TEX_FOOD
