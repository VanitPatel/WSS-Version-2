extends Node
class_name Terrain

# ─────────────────────────────────────────────────────────────────────────────
# Terrain.gd
# Defines all terrain types and their associated gameplay costs.
# This is a static data class — it holds no mutable state.
#
# Every MapCell stores a Terrain.Type int. When the Player or Brain needs
# to know the cost of entering a cell, they call Terrain.get_data(type).
#
# Adding a new terrain:
#   1. Add an entry to the Type enum.
#   2. Add a matching entry in TERRAIN_DATA with movement/water/food costs,
#      a single-character symbol, a display name, and a Color for the map.
#   3. Add weights for the new type in GameMap.DIFFICULTY_WEIGHTS.
# ─────────────────────────────────────────────────────────────────────────────

# Terrain categories (the int values are used as dictionary keys)
enum Type {
	PLAINS,    # 0 – cheapest; default open land
	MOUNTAIN,  # 1 – very expensive; drains strength quickly
	DESERT,    # 2 – moderate movement; drains water heavily
	SWAMP,     # 3 – moderate movement; drains strength and food
	FOREST     # 4 – moderate movement; relatively gentle on resources
}

# ── Terrain cost table ────────────────────────────────────────────────────────
# Each entry is a Dictionary with these keys:
#   "movement" – strength points spent per step on this terrain
#   "water"    – water points spent per step
#   "food"     – food points spent per step
#   "symbol"   – single character shown on the ASCII map (Main.gd)
#   "name"     – human-readable label used in turn log messages
#   "color"    – Color displayed in the map grid buttons (Main.gd)
const TERRAIN_DATA = {
	# Plains: cheapest terrain; ideal for fast east travel
	Type.PLAINS:   { "movement": 1, "water": 1, "food": 1, "symbol": "P", "name": "Plains",   "color": Color(0.6, 0.9, 0.4) },
	# Mountain: costs 4 strength per step; avoid unless path is blocked
	Type.MOUNTAIN: { "movement": 4, "water": 2, "food": 2, "symbol": "M", "name": "Mountain", "color": Color(0.6, 0.6, 0.6) },
	# Desert: costs 3 water per step; dangerous without water reserves
	Type.DESERT:   { "movement": 2, "water": 3, "food": 1, "symbol": "D", "name": "Desert",   "color": Color(0.95, 0.85, 0.5) },
	# Swamp: moderate cost; drains food as well as movement
	Type.SWAMP:    { "movement": 3, "water": 1, "food": 2, "symbol": "S", "name": "Swamp",    "color": Color(0.4, 0.6, 0.3) },
	# Forest: mild cost; a good route when plains are unavailable
	Type.FOREST:   { "movement": 2, "water": 1, "food": 1, "symbol": "F", "name": "Forest",   "color": Color(0.2, 0.55, 0.2) },
}

# ─────────────────────────────────────────────────────────────────────────────
# get_data(type) -> Dictionary
# Static accessor — returns the cost/display dictionary for a given Terrain.Type.
# Used by MapCell.get_terrain_data() and directly by Player/Brain logic.
# ─────────────────────────────────────────────────────────────────────────────
static func get_data(type: int) -> Dictionary:
	return TERRAIN_DATA[type]
