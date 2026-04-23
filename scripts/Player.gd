extends RefCounted
class_name Player

# ─────────────────────────────────────────────────────────────────────────────
# Player.gd
# Represents the simulated player entity traversing the wilderness.
#
# Each turn the Player:
#   1. Asks its Brain which direction to move (or STAY to rest).
#   2. Validates the move (bounds check + resource check).
#   3. Applies terrain costs (strength/water/food drain).
#   4. Collects any items on the destination cell.
#   5. Checks whether it is still alive.
#
# The Player is a pure data/logic object — it has no knowledge of the
# visual scene. The gameboard scene reads Player.pos and Player.alive
# to update sprites and the HUD.
# ─────────────────────────────────────────────────────────────────────────────

# ── Identity ──────────────────────────────────────────────────────────────────
var player_name: String   # Display name shown in the HUD and log
var pos: Vector2i         # Current grid position (column, row)

# ── Resource maximums (set at creation, never change during a run) ─────────────
var max_strength: int
var max_water: int
var max_food: int

# ── Current resource levels (deplete as the player moves, replenish via items) ─
var current_strength: int
var current_water: int
var current_food: int
var current_gold: int = 0  # Gold starts at 0; spent at traders for water

# ── AI components (injected via setup() after construction) ───────────────────
var vision: Vision  # Determines which cells the player can "see"
var brain: Brain    # Decides which direction to move each turn

# ── Game state flags ──────────────────────────────────────────────────────────
var alive: bool = true   # Set to false when any resource hits 0; ends the game
var won: bool   = false  # Set to true when player reaches the east map edge
var turn_log: Array = [] # Per-turn log entries (currently unused but available)

# ─────────────────────────────────────────────────────────────────────────────
# Constructor
# pname    : Display name for this player
# strength : Starting (and max) strength points
# water    : Starting (and max) water points
# food     : Starting (and max) food points
# start_x  : Starting column (typically 0 = west edge)
# start_y  : Starting row    (typically map_height / 2 = vertical center)
# ─────────────────────────────────────────────────────────────────────────────
func _init(pname: String, strength: int, water: int, food: int, start_x: int, start_y: int):
	player_name      = pname
	max_strength     = strength
	max_water        = water
	max_food         = food
	current_strength = strength  # Start at full resources
	current_water    = water
	current_food     = food
	pos              = Vector2i(start_x, start_y)

# ─────────────────────────────────────────────────────────────────────────────
# setup(v, b)
# Injects the Vision and Brain objects after construction.
# Called by GameManager.start_game() once the vision/brain types are known.
# ─────────────────────────────────────────────────────────────────────────────
func setup(v: Vision, b: Brain):
	vision = v
	brain  = b

# ─────────────────────────────────────────────────────────────────────────────
# can_enter(terrain_data) -> bool
# Returns whether the player currently has enough resources to enter a tile.
# terrain_data is a Dictionary from Terrain.get_data(); it contains:
#   "movement" – strength cost  "water" – water cost  "food" – food cost
# All three must be affordable simultaneously for the move to be legal.
# ─────────────────────────────────────────────────────────────────────────────
func can_enter(terrain_data: Dictionary) -> bool:
	return (current_strength >= terrain_data["movement"] and
			current_water    >= terrain_data["water"]    and
			current_food     >= terrain_data["food"])

# ─────────────────────────────────────────────────────────────────────────────
# do_turn(game_map) -> String
# Advances the player by one turn. Returns a human-readable log string.
# This is the main per-turn entry point called by GameManager._do_turn().
#
# Turn sequence:
#   A. Brain chooses a direction string (e.g. "E", "NW", "STAY").
#   B. Validate the move:
#        - Out-of-bounds? → force STAY.
#        - Not enough resources? → force STAY.
#   C. Execute the action:
#        - STAY: recover +2 strength, pay half terrain cost.
#        - MOVE: pay full terrain cost, collect items at new position.
#   D. Check alive status.
# ─────────────────────────────────────────────────────────────────────────────
func do_turn(game_map: GameMap) -> String:
	turn_log.clear()
	if not alive:
		return "Player is dead."

	# Step A: Ask the Brain for a direction ("N","S","E","W","NE","NW","SE","SW","STAY")
	var move_dir = brain.make_move(self)
	var log      = "[" + player_name + "] "

	# ── Step B: Validate the proposed move ──────────────────────────────────
	if move_dir != "STAY":
		var offset = Vision.DIRECTIONS[move_dir]     # Convert direction string to (dx, dy) offset
		var nx     = pos.x + offset.x
		var ny     = pos.y + offset.y

		if not game_map.in_bounds(nx, ny):
			# The Brain tried to walk off the edge of the map
			log     += "Out of bounds (" + move_dir + "). Forced to rest. "
			move_dir = "STAY"
		else:
			var cell = game_map.get_cell(nx, ny)
			var td   = cell.get_terrain_data()
			if not can_enter(td):
				# Not enough resources to afford entering that terrain type
				log     += "Too tired for " + td["name"] + " (" + move_dir + "). Forced to rest. "
				move_dir = "STAY"

	# ── Step C: Execute the action ───────────────────────────────────────────
	if move_dir == "STAY":
		# Resting: recover strength, pay half the current cell's terrain costs
		current_strength = min(max_strength, current_strength + 2)
		var cell = game_map.get_cell(pos.x, pos.y)
		var td   = cell.get_terrain_data()
		# Use at least 1 water/food even if terrain normally costs 0
		current_water -= max(1, td["water"] / 2)
		current_food  -= max(1, td["food"]  / 2)
		log += "Rested at (" + str(pos.x) + "," + str(pos.y) + ")"
	else:
		# Moving: pay full terrain costs, collect items at the destination
		var offset = Vision.DIRECTIONS[move_dir]
		var nx     = pos.x + offset.x
		var ny     = pos.y + offset.y
		var cell   = game_map.get_cell(nx, ny)
		var td     = cell.get_terrain_data()

		# Update position and deduct resource costs
		pos              = Vector2i(nx, ny)
		current_strength -= td["movement"]
		current_water    -= td["water"]
		current_food     -= td["food"]
		log += "Moved " + move_dir + " → " + td["name"] + " (" + str(pos.x) + "," + str(pos.y) + ")"

		# Collect all available items on the new cell
		var to_remove = []  # Items that should be permanently removed after collection
		for item in cell.items:
			if item.can_collect():
				log += _collect_item(item)         # Apply item effect and append to log
				if not item.repeating:
					to_remove.append(item)         # One-time items get queued for removal
				else:
					item.collected_this_turn = true  # Prevent double-collecting a renewable

		# Remove one-time items from the cell permanently
		for item in to_remove:
			cell.items.erase(item)

	# Step D: Check if the player is still alive after resource deductions
	_check_alive(log)
	return log

# ─────────────────────────────────────────────────────────────────────────────
# _collect_item(item) -> String  (private)
# Applies the effect of collecting an item and returns a log snippet.
# For TRADER: auto-trades 1 gold for 2 water if the player is thirsty.
# ─────────────────────────────────────────────────────────────────────────────
func _collect_item(item: Item) -> String:
	match item.item_type:
		Item.Type.FOOD_BONUS:
			# Cap food at the maximum; don't overfill
			current_food = min(max_food, current_food + item.amount)
			return " | Collected food +" + str(item.amount)

		Item.Type.WATER_BONUS:
			current_water = min(max_water, current_water + item.amount)
			return " | Collected water +" + str(item.amount)

		Item.Type.GOLD_BONUS:
			# Gold has no cap — accumulate indefinitely
			current_gold += item.amount
			return " | Collected gold +" + str(item.amount)

		Item.Type.TRADER:
			# Simple auto-trade logic: spend 1 gold to get 2 water if below half water
			if current_gold >= 1 and current_water < max_water / 2:
				current_gold  -= 1
				current_water  = min(max_water, current_water + 2)
				return " | Traded 1 gold → 2 water"
			return " | Met trader (no trade)"  # Had no gold or didn't need water
	return ""

# ─────────────────────────────────────────────────────────────────────────────
# _check_alive(log)  (private)
# Sets alive = false if any vital resource has dropped to/below zero.
# Strength can go negative briefly (< 0) before we catch it;
# water and food kill at exactly 0 or below.
# ─────────────────────────────────────────────────────────────────────────────
func _check_alive(log: String):
	if current_strength < 0 or current_water <= 0 or current_food <= 0:
		alive = false  # GameManager will detect this and emit game_over

# ─────────────────────────────────────────────────────────────────────────────
# get_status() -> String
# Returns a compact one-line summary of the player's current stats.
# Displayed in the HUD status bar each turn.
# Example: "Explorer | STR:42/50 H2O:30/50 FOOD:18/50 GOLD:3"
# ─────────────────────────────────────────────────────────────────────────────
func get_status() -> String:
	return (player_name + " | STR:"  + str(current_strength) + "/" + str(max_strength) +
			" H2O:"  + str(current_water)    + "/" + str(max_water)    +
			" FOOD:" + str(current_food)     + "/" + str(max_food)     +
			" GOLD:" + str(current_gold))
