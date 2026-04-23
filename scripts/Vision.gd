extends RefCounted
class_name Vision

# Directions as Vector2i offsets
const DIRECTIONS = {
	"N":  Vector2i(0, -1),
	"S":  Vector2i(0,  1),
	"E":  Vector2i(1,  0),
	"W":  Vector2i(-1, 0),
	"NE": Vector2i(1, -1),
	"NW": Vector2i(-1,-1),
	"SE": Vector2i(1,  1),
	"SW": Vector2i(-1, 1),
}

var visible_dirs: Array  # which direction keys this vision can see
var map: GameMap
var vision_range: int = 1 # NEW: Determines how many cells ahead the player can see

# Vision type metadata (for UI display)
var vision_name: String = ""
var vision_desc: String = ""

func _init(dirs: Array, game_map: GameMap, range: int = 1):
	visible_dirs = dirs
	map = game_map
	vision_range = range # Set the range when creating the vision

# Returns Array of Vector2i positions visible from (px, py)
# Returns Array of Vector2i positions visible from (px, py)
func get_visible_cells(px: int, py: int) -> Array:
	var result = []
	for dir_name in visible_dirs:
		var offset = DIRECTIONS[dir_name]
		
		# Look ahead up to the vision_range limit
		for step in range(1, vision_range + 1):
			var nx = px + (offset.x * step)
			var ny = py + (offset.y * step)
			
			if map.in_bounds(nx, ny):
				result.append(Vector2i(nx, ny))
			else:
				break # Stop looking in this direction if we hit the edge of the map
				
	return result

# Find closest cell containing an item of given type
func find_closest_item(px: int, py: int, item_type: int) -> Dictionary:
	var best = {}
	var best_cost = INF
	
	for dir_name in visible_dirs:
		var offset = DIRECTIONS[dir_name]
		
		# Look ahead up to the vision_range limit
		for step in range(1, vision_range + 1):
			var nx = px + (offset.x * step)
			var ny = py + (offset.y * step)
			
			if not map.in_bounds(nx, ny):
				break # Stop looking if map boundary is reached
				
			var cell = map.get_cell(nx, ny)
			var found_item = false
			
			for item in cell.items:
				if item.item_type == item_type and item.can_collect():
					# Use the distance (step) as the primary cost
					var cost = step 
					if cost < best_cost or (cost == best_cost and nx > best.get("pos", Vector2i(-1,0)).x):
						best_cost = cost
						best = {"pos": Vector2i(nx, ny), "dir": dir_name, "cost": cost}
					found_item = true
					break # Found the item, stop checking other items in this specific cell
			
			if found_item:
				break # We found the closest item in this direction, stop looking further outwards

	return best

func closest_food(px: int, py: int) -> Dictionary:
	return find_closest_item(px, py, Item.Type.FOOD_BONUS)

func closest_water(px: int, py: int) -> Dictionary:
	return find_closest_item(px, py, Item.Type.WATER_BONUS)

func closest_gold(px: int, py: int) -> Dictionary:
	return find_closest_item(px, py, Item.Type.GOLD_BONUS)

func closest_trader(px: int, py: int) -> Dictionary:
	return find_closest_item(px, py, Item.Type.TRADER)

func easiest_path(px: int, py: int) -> Dictionary:
	var best = {}
	var best_cost = INF
	for dir_name in visible_dirs:
		var offset = DIRECTIONS[dir_name]
		var nx = px + offset.x
		var ny = py + offset.y
		if not map.in_bounds(nx, ny):
			continue
		var cell = map.get_cell(nx, ny)
		var cost = cell.get_terrain_data()["movement"]
		if cost < best_cost or (cost == best_cost and nx > best.get("pos", Vector2i(-1,0)).x):
			best_cost = cost
			best = {"pos": Vector2i(nx, ny), "dir": dir_name, "cost": cost}
	return best


## --- Vision 1: Tunnel Vision ---
static func make_tunnel(game_map: GameMap) -> Vision:
	# Passes '5' as the vision_range
	var v = Vision.new(["E", "NE", "SE"], game_map, 5) 
	v.vision_name = "Tunnel"
	v.vision_desc = "Sees E, NE, SE up to 5 steps ahead. Fast but misses nearby resources."
	return v

# --- Vision 2: Standard ---
static func make_standard(game_map: GameMap) -> Vision:
	var v = Vision.new(["N", "S", "E", "W"], game_map, 5)
	v.vision_name = "Standard"
	v.vision_desc = "Sees N, S, E, W up to 5 steps ahead. Solid situational awareness."
	return v

# --- Vision 3: Panoramic ---
static func make_panoramic(game_map: GameMap) -> Vision:
	var v = Vision.new(["N", "S", "E", "W", "NE", "NW", "SE", "SW"], game_map, 5)
	v.vision_name = "Panoramic"
	v.vision_desc = "Sees all 8 directions up to 5 steps ahead. Best at finding resources."
	return v
