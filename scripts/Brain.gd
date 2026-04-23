extends RefCounted
class_name Brain

# ─────────────────────────────────────────────────────────────────────────────
# Brain.gd
# Defines the AI decision-making logic for the player character.
# A "Brain" is given to a Player and determines which direction to move each
# turn based on the player's current resource levels and what Vision can see.
#
# Three Brain types are available:
#   1. Brain (Survival)  – the base class; balances water, food, and rest.
#   2. AggressiveBrain   – rushes east; only grabs resources near death.
#   3. MerchantBrain     – hunts gold and traders to fund survival.
#
# New brains can be created by extending Brain and overriding make_move().
# ─────────────────────────────────────────────────────────────────────────────

# The Vision object this brain uses to look around the map
var vision: Vision

# Human-readable metadata shown in the UI
var brain_name: String = "Survival"
var brain_desc: String = "Prioritizes water and food. Falls back to moving east."

# Constructor: every Brain requires a Vision to observe the world
func _init(v: Vision):
	vision = v

# ─────────────────────────────────────────────────────────────────────────────
# Brain 1: Survival (the default / base Brain)
# Priority order each turn:
#   1. Seek water if water is ≤ 30% of max
#   2. Seek food  if food  is ≤ 30% of max
#   3. Rest       if strength is ≤ 30% of max
#   4. Move east  if the tile is passable
#   5. Take the easiest adjacent path as a fallback
# ─────────────────────────────────────────────────────────────────────────────
func make_move(player: Player) -> String:
	var px = player.pos.x
	var py = player.pos.y

	# Step 1: Head toward water if dangerously thirsty (≤30%)
	if player.current_water <= player.max_water * 0.3:
		var water = vision.closest_water(px, py)
		if not water.is_empty():
			return water["dir"]  # Return direction string e.g. "NE", "W"

	# Step 2: Head toward food if dangerously hungry (≤30%)
	if player.current_food <= player.max_food * 0.3:
		var food = vision.closest_food(px, py)
		if not food.is_empty():
			return food["dir"]

	# Step 3: Rest in place if too exhausted to move safely (≤30% strength)
	if player.current_strength <= player.max_strength * 0.3:
		return "STAY"  # Resting recovers 2 strength per turn

	# Step 4: Attempt to move one step east (the goal direction)
	var east_cell = vision.map.get_cell(px + 1, py)
	if east_cell != null:
		var data = east_cell.get_terrain_data()
		if player.can_enter(data):   # Check if player has enough resources
			return "E"

	# Step 5: Fallback — take whichever adjacent cell costs the least movement
	var easy = vision.easiest_path(px, py)
	if not easy.is_empty() and player.can_enter(vision.map.get_cell(easy["pos"].x, easy["pos"].y).get_terrain_data()):
		return easy["dir"]

	# No good move found; stay put and rest
	return "STAY"


# ─────────────────────────────────────────────────────────────────────────────
# Brain 2: Aggressive
# A sub-class of Brain that charges east as fast as possible.
# Only detours for water or food when a single point away from death.
# ─────────────────────────────────────────────────────────────────────────────
class AggressiveBrain extends Brain:
	func _init(v: Vision):
		super(v)  # Call parent Brain._init to store the Vision reference
		brain_name = "Aggressive"
		brain_desc = "Charges east at all costs. Grabs resources only when nearly dead."

	func make_move(player: Player) -> String:
		var px = player.pos.x
		var py = player.pos.y

		# Only divert for resources when one resource unit away from death
		if player.current_water <= 1 or player.current_food <= 1:
			var water = vision.closest_water(px, py)
			if not water.is_empty():
				return water["dir"]
			var food = vision.closest_food(px, py)
			if not food.is_empty():
				return food["dir"]

		# Primary goal: move east every turn if possible
		var east_cell = vision.map.get_cell(px + 1, py)
		if east_cell != null:
			var data = east_cell.get_terrain_data()
			if player.can_enter(data):
				return "E"

		# If east is blocked, try diagonal-east directions then cardinal N/S
		# This keeps overall eastward progress even when obstacles appear
		for dir in ["NE", "SE", "N", "S"]:
			var offset = Vision.DIRECTIONS[dir]
			var nx = px + offset.x
			var ny = py + offset.y
			if vision.map.in_bounds(nx, ny):
				var cell = vision.map.get_cell(nx, ny)
				if player.can_enter(cell.get_terrain_data()):
					return dir

		return "STAY"


# ─────────────────────────────────────────────────────────────────────────────
# Brain 3: Merchant
# A sub-class of Brain that collects gold and seeks traders.
# Uses gold to buy water/food from traders, sustaining a long eastern journey.
# ─────────────────────────────────────────────────────────────────────────────
class MerchantBrain extends Brain:
	func _init(v: Vision):
		super(v)
		brain_name = "Merchant"
		brain_desc = "Seeks gold and traders. Uses wealth to sustain the journey east."

	func make_move(player: Player) -> String:
		var px = player.pos.x
		var py = player.pos.y

		# Emergency survival: seek water at ≤20% (tighter threshold than Survival)
		if player.current_water <= player.max_water * 0.2:
			var water = vision.closest_water(px, py)
			if not water.is_empty():
				return water["dir"]

		# Emergency survival: seek food at ≤20%
		if player.current_food <= player.max_food * 0.2:
			var food = vision.closest_food(px, py)
			if not food.is_empty():
				return food["dir"]

		# If carrying gold and resources are below 60%, go find a trader to resupply
		if player.current_gold >= 1 and (player.current_water < player.max_water * 0.6 or player.current_food < player.max_food * 0.6):
			var trader = vision.closest_trader(px, py)
			if not trader.is_empty():
				return trader["dir"]

		# Opportunistically collect gold when not in any resource danger
		if player.current_water > player.max_water * 0.4 and player.current_food > player.max_food * 0.4:
			var gold = vision.closest_gold(px, py)
			if not gold.is_empty():
				return gold["dir"]

		# Rest if strength is very low (≤25%)
		if player.current_strength <= player.max_strength * 0.25:
			return "STAY"

		# Default: move east via the lowest-cost adjacent cell
		var east_cell = vision.map.get_cell(px + 1, py)
		if east_cell != null:
			var data = east_cell.get_terrain_data()
			if player.can_enter(data):
				return "E"

		var easy = vision.easiest_path(px, py)
		if not easy.is_empty() and player.can_enter(vision.map.get_cell(easy["pos"].x, easy["pos"].y).get_terrain_data()):
			return easy["dir"]

		return "STAY"


# ─────────────────────────────────────────────────────────────────────────────
# Static factory methods
# Convenience constructors called by GameManager to create the right brain type
# without the caller needing to know about the inner class names.
# ─────────────────────────────────────────────────────────────────────────────

# Creates the default balanced Survival brain
static func make_survival(v: Vision) -> Brain:
	return Brain.new(v)

# Creates the risk-taking Aggressive brain
static func make_aggressive(v: Vision) -> Brain:
	return AggressiveBrain.new(v)

# Creates the economy-focused Merchant brain
static func make_merchant(v: Vision) -> Brain:
	return MerchantBrain.new(v)
