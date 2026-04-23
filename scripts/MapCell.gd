extends RefCounted
class_name MapCell

# ─────────────────────────────────────────────────────────────────────────────
# MapCell.gd
# A single tile on the GameMap grid.
# Every cell knows:
#   • Its terrain type (Plains, Mountain, Desert, Swamp, Forest).
#   • Any items currently sitting on it (food, water, gold, trader).
#
# MapCell is a lightweight data container — it holds state but does not
# drive any behaviour itself. Behaviour is handled by Player and GameMap.
# ─────────────────────────────────────────────────────────────────────────────

var terrain_type: int   # A Terrain.Type enum value (int) describing this tile
var items: Array = []   # Array of Item objects currently on this cell

# ─────────────────────────────────────────────────────────────────────────────
# Constructor
# t : A Terrain.Type enum value (e.g. Terrain.Type.PLAINS)
# ─────────────────────────────────────────────────────────────────────────────
func _init(t: int):
	terrain_type = t

# ─────────────────────────────────────────────────────────────────────────────
# add_item(item)
# Appends an Item to this cell's item list.
# Called during map generation (GameMap._maybe_add_item) and never after.
# ─────────────────────────────────────────────────────────────────────────────
func add_item(item: Item):
	items.append(item)

# ─────────────────────────────────────────────────────────────────────────────
# get_terrain_data() -> Dictionary
# Returns the full data dict for this cell's terrain from Terrain.TERRAIN_DATA.
# The dict contains keys: "movement", "water", "food", "symbol", "name", "color".
# Example: { "movement": 1, "water": 1, "food": 1, "symbol": "P",
#             "name": "Plains", "color": Color(0.6, 0.9, 0.4) }
# ─────────────────────────────────────────────────────────────────────────────
func get_terrain_data() -> Dictionary:
	return Terrain.get_data(terrain_type)

# ─────────────────────────────────────────────────────────────────────────────
# has_trader() -> bool
# Returns true if at least one Trader item is on this cell.
# Used by Brain/Vision logic to locate nearby traders.
# ─────────────────────────────────────────────────────────────────────────────
func has_trader() -> bool:
	for item in items:
		if item.item_type == Item.Type.TRADER:
			return true
	return false

# ─────────────────────────────────────────────────────────────────────────────
# reset_turn()
# Propagates the turn-reset to every item on this cell.
# Called by GameMap.reset_turn() at the start of each new game turn.
# This allows repeating items (springs, traders) to be collected again.
# ─────────────────────────────────────────────────────────────────────────────
func reset_turn():
	for item in items:
		item.reset_turn()
