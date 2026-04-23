extends RefCounted
class_name MapCell

var terrain_type: int
var items: Array = []  # Array of Item

func _init(t: int):
	terrain_type = t

func add_item(item: Item):
	items.append(item)

func get_terrain_data() -> Dictionary:
	return Terrain.get_data(terrain_type)

func has_trader() -> bool:
	for item in items:
		if item.item_type == Item.Type.TRADER:
			return true
	return false

func reset_turn():
	for item in items:
		item.reset_turn()
