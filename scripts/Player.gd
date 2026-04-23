extends RefCounted
class_name Player

var player_name: String
var pos: Vector2i

var max_strength: int
var max_water: int
var max_food: int

var current_strength: int
var current_water: int
var current_food: int
var current_gold: int = 0

var vision: Vision
var brain: Brain

var alive: bool = true
var won: bool = false
var turn_log: Array = []

func _init(pname: String, strength: int, water: int, food: int, start_x: int, start_y: int):
	player_name = pname
	max_strength = strength
	max_water = water
	max_food = food
	current_strength = strength
	current_water = water
	current_food = food
	pos = Vector2i(start_x, start_y)

func setup(v: Vision, b: Brain):
	vision = v
	brain = b

func can_enter(terrain_data: Dictionary) -> bool:
	return (current_strength >= terrain_data["movement"] and
			current_water   >= terrain_data["water"] and
			current_food    >= terrain_data["food"])

# Execute one turn. Returns log string.
# Execute one turn. Returns log string.
func do_turn(game_map: GameMap) -> String:
	turn_log.clear()
	if not alive:
		return "Player is dead."

	var move_dir = brain.make_move(self)
	var log = "[" + player_name + "] "

	# --- NEW: Validate the move before executing it ---
	if move_dir != "STAY":
		var offset = Vision.DIRECTIONS[move_dir]
		var nx = pos.x + offset.x
		var ny = pos.y + offset.y

		if not game_map.in_bounds(nx, ny):
			log += "Out of bounds (" + move_dir + "). Forced to rest. "
			move_dir = "STAY" # Force the player to rest
		else:
			var cell = game_map.get_cell(nx, ny)
			var td = cell.get_terrain_data()
			if not can_enter(td):
				log += "Too tired for " + td["name"] + " (" + move_dir + "). Forced to rest. "
				move_dir = "STAY" # Force the player to rest to regain stamina

	# --- Execute Action ---
	if move_dir == "STAY":
		# Rest: regain 2 movement, half water/food cost
		current_strength = min(max_strength, current_strength + 2)
		var cell = game_map.get_cell(pos.x, pos.y)
		var td = cell.get_terrain_data()
		current_water -= max(1, td["water"] / 2)
		current_food  -= max(1, td["food"]  / 2)
		log += "Rested at (" + str(pos.x) + "," + str(pos.y) + ")"
	else:
		# The move was already validated above, so we can safely execute it
		var offset = Vision.DIRECTIONS[move_dir]
		var nx = pos.x + offset.x
		var ny = pos.y + offset.y
		var cell = game_map.get_cell(nx, ny)
		var td = cell.get_terrain_data()
		
		pos = Vector2i(nx, ny)
		current_strength -= td["movement"]
		current_water    -= td["water"]
		current_food     -= td["food"]
		log += "Moved " + move_dir + " → " + td["name"] + " (" + str(pos.x) + "," + str(pos.y) + ")"

		# Collect items
		var to_remove = []
		for item in cell.items:
			if item.can_collect():
				log += _collect_item(item)
				if not item.repeating:
					to_remove.append(item)
				else:
					item.collected_this_turn = true
		for item in to_remove:
			cell.items.erase(item)

	_check_alive(log)
	return log
func _collect_item(item: Item) -> String:
	match item.item_type:
		Item.Type.FOOD_BONUS:
			current_food = min(max_food, current_food + item.amount)
			return " | Collected food +" + str(item.amount)
		Item.Type.WATER_BONUS:
			current_water = min(max_water, current_water + item.amount)
			return " | Collected water +" + str(item.amount)
		Item.Type.GOLD_BONUS:
			current_gold += item.amount
			return " | Collected gold +" + str(item.amount)
		Item.Type.TRADER:
			# Simple auto-trade: trade 1 gold for 2 water if thirsty
			if current_gold >= 1 and current_water < max_water / 2:
				current_gold -= 1
				current_water = min(max_water, current_water + 2)
				return " | Traded 1 gold → 2 water"
			return " | Met trader (no trade)"
	return ""

func _check_alive(log: String):
	# Changed current_strength <= 0 to current_strength < 0
	if current_strength < 0 or current_water <= 0 or current_food <= 0:
		alive = false

func get_status() -> String:
	return (player_name + " | STR:" + str(current_strength) + "/" + str(max_strength) +
		" H2O:" + str(current_water) + "/" + str(max_water) +
		" FOOD:" + str(current_food) + "/" + str(max_food) +
		" GOLD:" + str(current_gold))
