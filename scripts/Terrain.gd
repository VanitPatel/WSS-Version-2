extends Node
class_name Terrain

enum Type {
	PLAINS,
	MOUNTAIN,
	DESERT,
	SWAMP,
	FOREST
}

# Each terrain: { movement_cost, water_cost, food_cost, symbol, color }
const TERRAIN_DATA = {
	Type.PLAINS:   { "movement": 1, "water": 1, "food": 1, "symbol": "P", "name": "Plains",   "color": Color(0.6, 0.9, 0.4) },
	Type.MOUNTAIN: { "movement": 4, "water": 2, "food": 2, "symbol": "M", "name": "Mountain", "color": Color(0.6, 0.6, 0.6) },
	Type.DESERT:   { "movement": 2, "water": 3, "food": 1, "symbol": "D", "name": "Desert",   "color": Color(0.95, 0.85, 0.5) },
	Type.SWAMP:    { "movement": 3, "water": 1, "food": 2, "symbol": "S", "name": "Swamp",    "color": Color(0.4, 0.6, 0.3) },
	Type.FOREST:   { "movement": 2, "water": 1, "food": 1, "symbol": "F", "name": "Forest",   "color": Color(0.2, 0.55, 0.2) },
}

static func get_data(type: int) -> Dictionary:
	return TERRAIN_DATA[type]
