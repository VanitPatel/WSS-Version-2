extends Node
class_name Item

enum Type {
	FOOD_BONUS,
	WATER_BONUS,
	GOLD_BONUS,
	TRADER
}

var item_type: int
var amount: int
var repeating: bool
var collected_this_turn: bool = false

func _init(type: int, amt: int, is_repeating: bool = false):
	item_type = type
	amount = amt
	repeating = is_repeating

func get_label() -> String:
	match item_type:
		Type.FOOD_BONUS:  return "Food(+" + str(amount) + ")" + ("*" if repeating else "")
		Type.WATER_BONUS: return "Water(+" + str(amount) + ")" + ("*" if repeating else "")
		Type.GOLD_BONUS:  return "Gold(+" + str(amount) + ")" + ("*" if repeating else "")
		Type.TRADER:      return "Trader"
	return "?"

func can_collect() -> bool:
	if repeating:
		return not collected_this_turn
	return true  # one-time items are removed after collection

func reset_turn():
	collected_this_turn = false
