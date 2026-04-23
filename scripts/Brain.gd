extends RefCounted
class_name Brain

var vision: Vision

# Brain type metadata (for UI display)
var brain_name: String = "Survival"
var brain_desc: String = "Prioritizes water and food. Falls back to moving east."

func _init(v: Vision):
	vision = v

# --- Brain 1: Survival (default) ---
# Prioritizes water > food > rest > east movement.
func make_move(player: Player) -> String:
	var px = player.pos.x
	var py = player.pos.y

	if player.current_water <= player.max_water * 0.3:
		var water = vision.closest_water(px, py)
		if not water.is_empty():
			return water["dir"]

	if player.current_food <= player.max_food * 0.3:
		var food = vision.closest_food(px, py)
		if not food.is_empty():
			return food["dir"]

	if player.current_strength <= player.max_strength * 0.3:
		return "STAY"  # Rest to recover strength

	# Default: take easiest eastward path
	var east_cell = vision.map.get_cell(px + 1, py)
	if east_cell != null:
		var data = east_cell.get_terrain_data()
		if player.can_enter(data):
			return "E"

	# Fall back to easiest neighboring cell
	var easy = vision.easiest_path(px, py)
	if not easy.is_empty() and player.can_enter(vision.map.get_cell(easy["pos"].x, easy["pos"].y).get_terrain_data()):
		return easy["dir"]

	return "STAY"


# --- Brain 2: Aggressive ---
# Charges east as fast as possible. Only reacts to resources at death's door.
class AggressiveBrain extends Brain:
	func _init(v: Vision):
		super(v)
		brain_name = "Aggressive"
		brain_desc = "Charges east at all costs. Grabs resources only when nearly dead."

	func make_move(player: Player) -> String:
		var px = player.pos.x
		var py = player.pos.y

		# Only divert for resources at critical levels (1 point left)
		if player.current_water <= 1 or player.current_food <= 1:
			var water = vision.closest_water(px, py)
			if not water.is_empty():
				return water["dir"]
			var food = vision.closest_food(px, py)
			if not food.is_empty():
				return food["dir"]

		# Always try east first
		var east_cell = vision.map.get_cell(px + 1, py)
		if east_cell != null:
			var data = east_cell.get_terrain_data()
			if player.can_enter(data):
				return "E"

		# If blocked east, try diagonal east directions then N/S
		for dir in ["NE", "SE", "N", "S"]:
			var offset = Vision.DIRECTIONS[dir]
			var nx = px + offset.x
			var ny = py + offset.y
			if vision.map.in_bounds(nx, ny):
				var cell = vision.map.get_cell(nx, ny)
				if player.can_enter(cell.get_terrain_data()):
					return dir

		return "STAY"


# --- Brain 3: Merchant ---
# Actively hunts gold and traders, uses wealth to stay alive longer.
class MerchantBrain extends Brain:
	func _init(v: Vision):
		super(v)
		brain_name = "Merchant"
		brain_desc = "Seeks gold and traders. Uses wealth to sustain the journey east."

	func make_move(player: Player) -> String:
		var px = player.pos.x
		var py = player.pos.y

		# Critical survival first
		if player.current_water <= player.max_water * 0.2:
			var water = vision.closest_water(px, py)
			if not water.is_empty():
				return water["dir"]

		if player.current_food <= player.max_food * 0.2:
			var food = vision.closest_food(px, py)
			if not food.is_empty():
				return food["dir"]

		# Hunt traders if holding gold or if low on water/food
		if player.current_gold >= 1 and (player.current_water < player.max_water * 0.6 or player.current_food < player.max_food * 0.6):
			var trader = vision.closest_trader(px, py)
			if not trader.is_empty():
				return trader["dir"]

		# Grab gold opportunistically (when nearby and not in danger)
		if player.current_water > player.max_water * 0.4 and player.current_food > player.max_food * 0.4:
			var gold = vision.closest_gold(px, py)
			if not gold.is_empty():
				return gold["dir"]

		# Rest if strength is low
		if player.current_strength <= player.max_strength * 0.25:
			return "STAY"

		# Otherwise move east via the easiest path
		var east_cell = vision.map.get_cell(px + 1, py)
		if east_cell != null:
			var data = east_cell.get_terrain_data()
			if player.can_enter(data):
				return "E"

		var easy = vision.easiest_path(px, py)
		if not easy.is_empty() and player.can_enter(vision.map.get_cell(easy["pos"].x, easy["pos"].y).get_terrain_data()):
			return easy["dir"]

		return "STAY"


# --- Static factories ---
static func make_survival(v: Vision) -> Brain:
	return Brain.new(v)

static func make_aggressive(v: Vision) -> Brain:
	return AggressiveBrain.new(v)

static func make_merchant(v: Vision) -> Brain:
	return MerchantBrain.new(v)
