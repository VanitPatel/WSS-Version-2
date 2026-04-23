extends Node2D

@export var noise_height_texture : NoiseTexture2D
var seed = FastNoiseLite.new()
var noise : Noise

#Import TileSets
@onready var grassTileMap = $TileMap/grass
@onready var sandTileMap = $TileMap/sand
@onready var waterTileMap = $TileMap/water

var sourceid = 0
var wateratlas = Vector2i(5,2)
var landatlas =  Vector2i(4,4)

var grassTileCoor = []
var grassTerrainInt = 0
var sandTileCoor = []
var sandTerrainInt = 0
var waterTileCoor = []

#world size
@export var width : int = 100
@export var height : int = 100

func _ready():
	#randomize seed
	randomize()
	noise_height_texture.noise.seed = randi()
	print(noise_height_texture.noise.seed)
	noise = noise_height_texture.noise
	generate_world()


func generate_world():
	for x in range(width):
		for y in range(height):
			var noise_val = noise.get_noise_2d(x,y)
			#place grass
			if noise_val >= -0.2:
				#Place Sand -0.2 <= noise_val < 0.0
				if (noise_val >= -0.2 and noise_val<0.0):
					sandTileCoor.append(Vector2i(x,y))
				#Place Grass 0.0 <= noise_val
				else:
					grassTileCoor.append(Vector2i(x,y))
			#Place Water noise_val < -0.2
			elif noise_val	< -0.2:
				waterTileMap.set_cell(Vector2(x,y), sourceid, wateratlas)
			
	sandTileMap.set_cells_terrain_connect(sandTileCoor, sandTerrainInt, 0)
	grassTileMap.set_cells_terrain_connect(grassTileCoor, grassTerrainInt, 0)
	
	
	
	
