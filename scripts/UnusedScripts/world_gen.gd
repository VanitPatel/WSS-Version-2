extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
# world_gen.gd  (UNUSED / LEGACY)
# This was the original world generation script from an earlier version of the
# project.  It has been superseded by generateWorld.gd and is no longer
# attached to any active scene.  It is kept here for reference only.
#
# Differences from the current generateWorld.gd:
#   • Uses three separate TileMap child nodes (grass, sand, water) instead of
#     a single TileMapLayer with decoration children.
#   • Does not use decoration noise for tree/cactus overlays.
#   • Simpler threshold logic: sand = [-0.2, 0), grass = [0, +∞), water = (-∞, -0.2).
#   • Uses @export properties for width/height so they can be set in the Inspector.
# ─────────────────────────────────────────────────────────────────────────────

@export var noise_height_texture : NoiseTexture2D   # Assign in Inspector
var seed = FastNoiseLite.new()
var noise : Noise

# Legacy TileMap child node references (these node names no longer exist in scenes)
@onready var grassTileMap = $TileMap/grass
@onready var sandTileMap  = $TileMap/sand
@onready var waterTileMap = $TileMap/water

# Tile source/atlas constants for the old tileset layout
var sourceid   = 0
var wateratlas = Vector2i(5, 2)
var landatlas  = Vector2i(4, 4)

# Per-terrain tile coordinate lists for batch auto-tiling
var grassTileCoor  = []
var grassTerrainInt = 0
var sandTileCoor   = []
var sandTerrainInt  = 0
var waterTileCoor  = []

# World dimensions (editable in Inspector; not passed as parameters)
@export var width  : int = 100
@export var height : int = 100

func _ready():
	# Randomise noise seed and generate the world on startup
	randomize()
	noise_height_texture.noise.seed = randi()
	print(noise_height_texture.noise.seed)  # Debug: print seed to console
	noise = noise_height_texture.noise
	generate_world()


func generate_world():
	for x in range(width):
		for y in range(height):
			var noise_val = noise.get_noise_2d(x, y)

			if noise_val >= -0.2:
				# Mild negative to zero → Sand
				if (noise_val >= -0.2 and noise_val < 0.0):
					sandTileCoor.append(Vector2i(x, y))
				# Zero and above → Grass
				else:
					grassTileCoor.append(Vector2i(x, y))
			# Below -0.2 → Water (placed cell-by-cell, not batch auto-tiled)
			elif noise_val < -0.2:
				waterTileMap.set_cell(Vector2(x, y), sourceid, wateratlas)

	# Batch apply sand and grass tiles using auto-tiling for smooth borders
	sandTileMap.set_cells_terrain_connect(sandTileCoor, sandTerrainInt, 0)
	grassTileMap.set_cells_terrain_connect(grassTileCoor, grassTerrainInt, 0)
