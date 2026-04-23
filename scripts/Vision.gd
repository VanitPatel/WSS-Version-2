extends RefCounted
class_name Vision

# ─────────────────────────────────────────────────────────────────────────────
# Vision.gd
# Controls how far and in which directions the player can "see" the map.
# The Brain uses Vision to locate nearby resources (food, water, gold, traders)
# and to evaluate which adjacent cell is cheapest to move through.
#
# Three pre-built vision profiles are provided via static factory methods:
#   make_tunnel()    – sees only east and diagonals east; long range but narrow.
#   make_standard()  – sees all four cardinal directions; balanced.
#   make_panoramic() – sees all 8 directions; finds resources most reliably.
#
# All three look up to 5 cells ahead in each allowed direction.
# ─────────────────────────────────────────────────────────────────────────────

# Direction name → (dx, dy) offset for one step in that direction.
# Used by both Vision (for scanning) and Player (for move validation).
const DIRECTIONS = {
	"N":  Vector2i(0, -1),   # North  = up    (y decreases)
	"S":  Vector2i(0,  1),   # South  = down  (y increases)
	"E":  Vector2i(1,  0),   # East   = right (x increases) ← the goal direction
	"W":  Vector2i(-1, 0),   # West   = left  (x decreases)
	"NE": Vector2i(1, -1),   # Northeast diagonal
	"NW": Vector2i(-1,-1),   # Northwest diagonal
	"SE": Vector2i(1,  1),   # Southeast diagonal
	"SW": Vector2i(-1, 1),   # Southwest diagonal
}

var visible_dirs: Array   # List of direction name strings this vision can scan
var map: GameMap           # Reference to the game map for cell lookups
var vision_range: int = 1  # Max number of cells to scan in each direction

# Human-readable metadata shown in the options menu
var vision_name: String = ""
var vision_desc: String = ""

# ─────────────────────────────────────────────────────────────────────────────
# Constructor
# dirs      : Array of direction name strings (e.g. ["N","S","E","W"])
# game_map  : The GameMap instance to query
# range     : How many cells ahead to look in each direction (default 1)
# ─────────────────────────────────────────────────────────────────────────────
func _init(dirs: Array, game_map: GameMap, range: int = 1):
	visible_dirs = dirs
	map          = game_map
	vision_range = range

# ─────────────────────────────────────────────────────────────────────────────
# get_visible_cells(px, py) -> Array of Vector2i
# Returns all grid positions reachable by scanning in each allowed direction
# up to vision_range steps.  Stops early if the map boundary is hit.
# ─────────────────────────────────────────────────────────────────────────────
func get_visible_cells(px: int, py: int) -> Array:
	var result = []
	for dir_name in visible_dirs:
		var offset = DIRECTIONS[dir_name]
		# Walk step-by-step along this direction
		for step in range(1, vision_range + 1):
			var nx = px + (offset.x * step)
			var ny = py + (offset.y * step)
			if map.in_bounds(nx, ny):
				result.append(Vector2i(nx, ny))
			else:
				break  # Hit the map boundary; stop scanning further in this direction
	return result

# ─────────────────────────────────────────────────────────────────────────────
# find_closest_item(px, py, item_type) -> Dictionary
# Scans visible cells for the nearest item of the given type.
# Returns a dict: { "pos": Vector2i, "dir": String, "cost": int }
# or an empty dict {} if nothing is found.
#
# "cost" is the step distance (1 = adjacent, 2 = two tiles away, etc.).
# Ties are broken in favour of the cell with the larger x (more eastward).
# ─────────────────────────────────────────────────────────────────────────────
func find_closest_item(px: int, py: int, item_type: int) -> Dictionary:
	var best      = {}
	var best_cost = INF  # Start with infinity so any real find will beat it

	for dir_name in visible_dirs:
		var offset = DIRECTIONS[dir_name]
		for step in range(1, vision_range + 1):
			var nx = px + (offset.x * step)
			var ny = py + (offset.y * step)

			if not map.in_bounds(nx, ny):
				break  # Stop scanning this direction at map edge

			var cell      = map.get_cell(nx, ny)
			var found_item = false

			for item in cell.items:
				if item.item_type == item_type and item.can_collect():
					var cost = step  # Closer = lower cost = better
					# Prefer closer items; break ties by picking the eastward one
					if cost < best_cost or (cost == best_cost and nx > best.get("pos", Vector2i(-1,0)).x):
						best_cost = cost
						best      = {"pos": Vector2i(nx, ny), "dir": dir_name, "cost": cost}
					found_item = true
					break  # Only one item per cell matters; stop checking items here

			if found_item:
				break  # Found the closest item in this direction; stop scanning further

	return best

# ── Convenience wrappers ──────────────────────────────────────────────────────
# These call find_closest_item with the appropriate item type constant.
# Brain scripts use these directly, e.g. vision.closest_water(px, py).

func closest_food(px: int, py: int) -> Dictionary:
	return find_closest_item(px, py, Item.Type.FOOD_BONUS)

func closest_water(px: int, py: int) -> Dictionary:
	return find_closest_item(px, py, Item.Type.WATER_BONUS)

func closest_gold(px: int, py: int) -> Dictionary:
	return find_closest_item(px, py, Item.Type.GOLD_BONUS)

func closest_trader(px: int, py: int) -> Dictionary:
	return find_closest_item(px, py, Item.Type.TRADER)

# ─────────────────────────────────────────────────────────────────────────────
# easiest_path(px, py) -> Dictionary
# Looks one step in each visible direction and returns the adjacent cell
# with the lowest movement cost.
# Returns { "pos": Vector2i, "dir": String, "cost": int } or {} if none found.
# Used by the Brain as a fallback when it cannot move east.
# ─────────────────────────────────────────────────────────────────────────────
func easiest_path(px: int, py: int) -> Dictionary:
	var best      = {}
	var best_cost = INF
	for dir_name in visible_dirs:
		var offset = DIRECTIONS[dir_name]
		var nx     = px + offset.x
		var ny     = py + offset.y
		if not map.in_bounds(nx, ny):
			continue
		var cell = map.get_cell(nx, ny)
		var cost = cell.get_terrain_data()["movement"]
		# Prefer cheapest; break ties by preferring the more eastward cell
		if cost < best_cost or (cost == best_cost and nx > best.get("pos", Vector2i(-1,0)).x):
			best_cost = cost
			best      = {"pos": Vector2i(nx, ny), "dir": dir_name, "cost": cost}
	return best


# ─────────────────────────────────────────────────────────────────────────────
# Vision factory methods
# Each creates a Vision with a specific set of directions and a range of 5.
# ─────────────────────────────────────────────────────────────────────────────

# Tunnel Vision: sees E, NE, SE up to 5 tiles.
# Fast at finding eastern resources; misses things to the north/south/west.
static func make_tunnel(game_map: GameMap) -> Vision:
	var v         = Vision.new(["E", "NE", "SE"], game_map, 5)
	v.vision_name = "Tunnel"
	v.vision_desc = "Sees E, NE, SE up to 5 steps ahead. Fast but misses nearby resources."
	return v

# Standard Vision: sees N, S, E, W up to 5 tiles.
# Good all-around awareness without the full cost of panoramic scanning.
static func make_standard(game_map: GameMap) -> Vision:
	var v         = Vision.new(["N", "S", "E", "W"], game_map, 5)
	v.vision_name = "Standard"
	v.vision_desc = "Sees N, S, E, W up to 5 steps ahead. Solid situational awareness."
	return v

# Panoramic Vision: sees all 8 directions up to 5 tiles.
# Best at locating resources; the Brain can make the most informed choices.
static func make_panoramic(game_map: GameMap) -> Vision:
	var v         = Vision.new(["N", "S", "E", "W", "NE", "NW", "SE", "SW"], game_map, 5)
	v.vision_name = "Panoramic"
	v.vision_desc = "Sees all 8 directions up to 5 steps ahead. Best at finding resources."
	return v
