extends Node
class_name GameMap

# ─────────────────────────────────────────────────────────────────────────────
# GameMap.gd
# Represents the full simulation grid (not the visual tilemap).
# Each tile on the grid is a MapCell that stores a terrain type and any items.
#
# Usage:
#   var gmap = GameMap.new()
#   gmap.generate(60, 40, "easy")  # width, height, difficulty
#   var cell = gmap.get_cell(x, y) -> MapCell
# ─────────────────────────────────────────────────────────────────────────────

var width: int   # Number of columns
var height: int  # Number of rows
var cells: Array = []  # 2-D array indexed as cells[x][y]; each element is a MapCell

# ── Terrain probability weights per difficulty ────────────────────────────────
# Index order matches Terrain.Type enum: Plains, Mountain, Desert, Swamp, Forest
# Higher numbers = more tiles of that type spawned.
# "easy"  is mostly Plains (safe, cheap to cross).
# "hard"  is mostly Mountains and Deserts (expensive, resource-draining).
const DIFFICULTY_WEIGHTS = {
	"easy":   [40, 10, 10, 10, 30],  # Mostly plains and forest — forgiving
	"normal": [25, 20, 20, 15, 20],  # Balanced mix
	"hard":   [10, 30, 30, 20, 10],  # Mostly mountains and deserts — brutal
}

# Probability that any given cell will have an item placed in it
const ITEM_CHANCE = 0.15  # 15% chance per cell

# ─────────────────────────────────────────────────────────────────────────────
# generate(w, h, difficulty)
# Fills the cells array with MapCell objects.
# Called once per game session from GameManager.start_game().
# ─────────────────────────────────────────────────────────────────────────────
func generate(w: int, h: int, difficulty: String):
	width  = w
	height = h
	cells  = []

	# Look up the terrain weight array; fall back to "normal" for unknown strings
	var weights = DIFFICULTY_WEIGHTS.get(difficulty, DIFFICULTY_WEIGHTS["normal"])

	# Build the 2-D grid column by column
	for x in range(width):
		var col = []
		for y in range(height):
			var terrain = _pick_terrain(weights)  # Randomly choose terrain type
			var cell    = MapCell.new(terrain)
			_maybe_add_item(cell)                  # Randomly sprinkle an item
			col.append(cell)
		cells.append(col)

# ─────────────────────────────────────────────────────────────────────────────
# get_cell(x, y) -> MapCell or null
# Safe accessor — returns null if coordinates are out of bounds.
# Always check for null before using the result.
# ─────────────────────────────────────────────────────────────────────────────
func get_cell(x: int, y: int) -> MapCell:
	if x < 0 or x >= width or y < 0 or y >= height:
		return null
	return cells[x][y]

# ─────────────────────────────────────────────────────────────────────────────
# in_bounds(x, y) -> bool
# Quick boundary check used by Vision and Player before accessing cells.
# ─────────────────────────────────────────────────────────────────────────────
func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

# ─────────────────────────────────────────────────────────────────────────────
# _pick_terrain(weights) -> int  (private)
# Weighted random selection: rolls a number then walks through cumulative totals
# to find which bucket it falls in.  Returns a Terrain.Type int index.
# ─────────────────────────────────────────────────────────────────────────────
func _pick_terrain(weights: Array) -> int:
	# Sum all weights to know the total "lottery ticket" pool
	var total = 0
	for w in weights:
		total += w

	var roll       = randi() % total  # Pick a random ticket
	var cumulative = 0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return i   # This terrain type won
	return 0  # Fallback: return Plains (should never be reached)

# ─────────────────────────────────────────────────────────────────────────────
# _maybe_add_item(cell)  (private)
# With 15% probability, adds a random item to the given cell.
# Item distribution:
#   30% → Food bonus  (amount 2-5, 30% chance of being repeating/renewable)
#   25% → Water bonus (amount 2-5, 40% chance of being repeating/renewable)
#   20% → Gold bonus  (amount 1-3, never repeating)
#   25% → Trader      (special interaction item, always repeating)
# ─────────────────────────────────────────────────────────────────────────────
func _maybe_add_item(cell: MapCell):
	# Roll to see if this cell gets any item at all
	if randf() > ITEM_CHANCE:
		return  # No item this time

	var roll = randf()  # Second roll decides which item type
	if roll < 0.30:
		# Food: amount between 2-5, 30% chance it regenerates each turn
		cell.add_item(Item.new(Item.Type.FOOD_BONUS, randi_range(2, 5), randf() < 0.3))
	elif roll < 0.55:
		# Water: amount between 2-5, 40% chance it regenerates each turn
		cell.add_item(Item.new(Item.Type.WATER_BONUS, randi_range(2, 5), randf() < 0.4))
	elif roll < 0.75:
		# Gold: amount between 1-3, one-time pickup (not repeating)
		cell.add_item(Item.new(Item.Type.GOLD_BONUS, randi_range(1, 3), false))
	else:
		# Trader NPC: always repeating (player can visit multiple times)
		cell.add_item(Item.new(Item.Type.TRADER, 0, true))

# ─────────────────────────────────────────────────────────────────────────────
# reset_turn()
# Called at the start of each game turn by GameManager._do_turn().
# Tells every item on every cell to reset its "collected this turn" flag
# so that repeating/renewable items can be picked up again next turn.
# ─────────────────────────────────────────────────────────────────────────────
func reset_turn():
	for col in cells:
		for cell in col:
			cell.reset_turn()
