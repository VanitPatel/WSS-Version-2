extends Node2D

class_name GenerateWorld

# ─────────────────────────────────────────────────────────────────────────────
# generateWorld.gd
# Procedurally generates the visual tile map using Simplex/Perlin noise.
# This is the VISUAL layer — it renders tiles on screen using Godot TileMapLayers.
# It is completely separate from the GameMap simulation grid (GameMap.gd).
#
# How it works:
#   1. Two noise textures are generated: one for terrain height, one for decoration.
#   2. For each (x, y) tile coordinate, the height noise value determines
#      which terrain tile to draw (sand, water, forest, or grass).
#   3. The decoration noise determines where to place cactus and tree overlays.
#
# Called from:
#   • gameboard.gd._ready()   – generates the game world
#   • main_menu.gd._ready()   – generates a random decorative background
# ─────────────────────────────────────────────────────────────────────────────

# ── Coordinate lists ──────────────────────────────────────────────────────────
# These arrays collect the grid positions of each terrain type.
# After the loop they are passed to TileMapLayer.set_cells_terrain_connect()
# so Godot's auto-tiling can join adjacent tiles into smooth borders.
var grassTileCoor  = []  # Positions of grass tiles (default terrain)
var waterTileCoor  = []  # Positions of water tiles
var sandTileCoor   = []  # Positions of sand/desert tiles
var forestTileCoor = []  # Positions of forest tiles
var cactusTileCoor = []  # Positions of cactus decoration (on sand)
var treeTileCoor   = []  # Positions of tree decoration (in forest)

# ── Tile atlas coordinates ────────────────────────────────────────────────────
# These Vector2 values reference specific tiles inside the tileset texture atlas.
var grassTerrainInt = 0                                    # Terrain index for auto-tiled grass
var terrainSet      = 0                                    # Source ID in the TileSet resource
var waterAtlas      = Vector2(10, 5)                       # Atlas position of the water tile
var sandAtlas       = Vector2(10, 1)                       # Atlas position of the sand tile
var forestAtlas     = [Vector2(10, 9), Vector2(12, 8)]    # Two random forest tile variants

# ── Noise generators ─────────────────────────────────────────────────────────
# noise      – Simplex smooth noise; determines terrain type (height map)
# noiseDeco  – Perlin noise; determines decoration placement
var noise      : Noise
var noiseDeco  : Noise

# ─────────────────────────────────────────────────────────────────────────────
# createNoiseTexture(seed)
# Initialises both noise generators with the same seed so terrain and
# decoration are spatially correlated (e.g. cacti appear in sandy areas).
# If seed is null a random one is generated.
# ─────────────────────────────────────────────────────────────────────────────
func createNoiseTexture(seed = null) -> void:
	var noise_deco_texture   = NoiseTexture2D.new()
	var noise_height_texture = NoiseTexture2D.new()

	# Randomise the seed if the caller didn't supply one
	if seed == null:
		randomize()
		seed = randi()

	# Height noise: Simplex Smooth produces gentle rolling hills
	var heightFNL         = FastNoiseLite.new()
	heightFNL.noise_type  = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	heightFNL.seed        = seed
	noise_height_texture.noise = heightFNL

	# Decoration noise: standard Perlin with higher frequency for denser variation
	var decoFNL           = FastNoiseLite.new()
	decoFNL.noise_type    = FastNoiseLite.TYPE_PERLIN
	decoFNL.seed          = seed
	decoFNL.frequency     = 0.9   # Higher frequency = more rapid variation
	noise_deco_texture.noise = decoFNL

	# Store the underlying Noise objects for per-pixel queries
	noise      = noise_height_texture.noise
	noiseDeco  = noise_deco_texture.noise

# ─────────────────────────────────────────────────────────────────────────────
# generateWorld(tileMapPath, noise, xSize, ySize, seed)
# Iterates over every (x, y) position in the grid and assigns a terrain type
# based on the noise value at that position, then places tiles on the map.
#
# noise_val thresholds (Simplex output is roughly -1.0 to +1.0):
#   > 0.4   → Sand / Desert  (high elevation)
#   0.0–0.1 → Water / River  (slight dip)
#   < -0.4  → Forest         (low elevation)
#   else    → Grass          (mid elevation, most common)
#
# tileMapPath : The TileMapLayer node whose children are the ground and deco layers
# ─────────────────────────────────────────────────────────────────────────────
func generateWorld(tileMapPath: TileMapLayer, noise: Noise, xSize: int = 100, ySize: int = 100, seed = null) -> void:
	createNoiseTexture()  # Initialise noise (ignores the seed param; uses internal randomize)

	# Get the two TileMapLayer children: index 0 = ground, index 1 = decoration overlay
	var groundTileMap = tileMapPath.get_child(0)
	var decoTileMap   = tileMapPath.get_child(1)

	# Sample noise at every tile coordinate and classify terrain
	for x in range(xSize):
		for y in range(ySize):
			var noise_val  = noise.get_noise_2d(x, y)       # Height value for this tile
			var deco_noise = noiseDeco.get_noise_2d(x, y)   # Decoration density here

			if noise_val > 0.4:
				# High elevation → Sand / Desert tile
				groundTileMap.set_cell(Vector2(x, y), terrainSet, sandAtlas)
				sandTileCoor.append(Vector2i(x, y))
				# Sparse cacti appear on the sandiest, driest spots
				if noise_val > 0.45 and deco_noise > 0.3:
					cactusTileCoor.append(Vector2i(x, y))

			elif noise_val > 0.0 and noise_val < 0.1:
				# Slight dip in elevation → Water / River tile
				groundTileMap.set_cell(Vector2(x, y), terrainSet, waterAtlas)
				waterTileCoor.append(Vector2i(x, y))

			elif noise_val < -0.4:
				# Low elevation → Forest tile (pick one of two random variants)
				groundTileMap.set_cell(Vector2(x, y), terrainSet, forestAtlas.pick_random())
				forestTileCoor.append(Vector2i(x, y))
				# Trees appear throughout the forest where deco noise is above threshold
				if deco_noise > -0.1:
					treeTileCoor.append(Vector2i(x, y))

			else:
				# Mid elevation → Grass (collected for batch auto-tiling below)
				grassTileCoor.append(Vector2i(x, y))

	# ── Apply tiles in batch using Godot's auto-tiling system ─────────────────
	# set_cells_terrain_connect() automatically chooses the correct tile variant
	# (corners, edges, centre) based on neighbouring cells for smooth blending.
	groundTileMap.set_cells_terrain_connect(grassTileCoor, terrainSet, grassTerrainInt)
	decoTileMap.set_cells_terrain_connect(cactusTileCoor, terrainSet, 1)  # Cactus terrain layer
	decoTileMap.set_cells_terrain_connect(treeTileCoor, 1, 0)             # Tree terrain layer
