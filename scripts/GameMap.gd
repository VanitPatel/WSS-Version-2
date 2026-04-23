extends Node
class_name GameMap

var width: int
var height: int
var cells: Array = []  # 2D array [x][y]

const DIFFICULTY_WEIGHTS = {
	"easy":   [40, 10, 10, 10, 30],  # Plains,Mountain,Desert,Swamp,Forest
	"normal": [25, 20, 20, 15, 20],
	"hard":   [10, 30, 30, 20, 10],
}

const ITEM_CHANCE = 0.15  # 15% of cells get an item

func generate(w: int, h: int, difficulty: String):
	width = w
	height = h
	cells = []
	var weights = DIFFICULTY_WEIGHTS.get(difficulty, DIFFICULTY_WEIGHTS["normal"])

	for x in range(width):
		var col = []
		for y in range(height):
			var terrain = _pick_terrain(weights)
			var cell = MapCell.new(terrain)
			_maybe_add_item(cell)
			col.append(cell)
		cells.append(col)

func get_cell(x: int, y: int) -> MapCell:
	if x < 0 or x >= width or y < 0 or y >= height:
		return null
	return cells[x][y]

func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

func _pick_terrain(weights: Array) -> int:
	var total = 0
	for w in weights:
		total += w
	var roll = randi() % total
	var cumulative = 0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return i
	return 0

func _maybe_add_item(cell: MapCell):
	if randf() > ITEM_CHANCE:
		return
	var roll = randf()
	if roll < 0.30:
		cell.add_item(Item.new(Item.Type.FOOD_BONUS, randi_range(2, 5), randf() < 0.3))
	elif roll < 0.55:
		cell.add_item(Item.new(Item.Type.WATER_BONUS, randi_range(2, 5), randf() < 0.4))
	elif roll < 0.75:
		cell.add_item(Item.new(Item.Type.GOLD_BONUS, randi_range(1, 3), false))
	else:
		cell.add_item(Item.new(Item.Type.TRADER, 0, true))

func reset_turn():
	for col in cells:
		for cell in col:
			cell.reset_turn()
