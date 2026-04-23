extends Node
class_name Item

# ─────────────────────────────────────────────────────────────────────────────
# Item.gd
# Represents a collectible or interactive object that can sit inside a MapCell.
#
# Items fall into four types:
#   FOOD_BONUS  – restores food when the player steps onto the cell.
#   WATER_BONUS – restores water when the player steps onto the cell.
#   GOLD_BONUS  – adds gold to the player's inventory (used to trade).
#   TRADER      – triggers an auto-trade interaction (see Player._collect_item).
#
# Items can be "repeating" (renewable springs, persistent traders) or one-time
# pickups (a pile of food, a gold nugget). One-time items are removed from
# the cell after collection; repeating items reset each turn.
# ─────────────────────────────────────────────────────────────────────────────

# All possible item categories
enum Type {
	FOOD_BONUS,   # Grants food points when collected
	WATER_BONUS,  # Grants water points when collected
	GOLD_BONUS,   # Grants gold coins when collected
	TRADER        # Special NPC; triggers a trade offer
}

var item_type: int              # One of the Type enum values above
var amount: int                 # How much resource is granted (0 for TRADER)
var repeating: bool             # True → item resets each turn and is never removed
var collected_this_turn: bool = false  # Flag to prevent collecting a repeating item twice in one turn

# ─────────────────────────────────────────────────────────────────────────────
# Constructor
# type         : Item.Type enum value
# amt          : Resource amount (ignored for TRADER)
# is_repeating : Whether the item can be collected again next turn
# ─────────────────────────────────────────────────────────────────────────────
func _init(type: int, amt: int, is_repeating: bool = false):
	item_type  = type
	amount     = amt
	repeating  = is_repeating

# ─────────────────────────────────────────────────────────────────────────────
# get_label() -> String
# Returns a short display string for debugging or UI tooltips.
# A "*" suffix means the item is repeating/renewable.
# Example outputs: "Food(+3)*", "Water(+2)", "Gold(+1)", "Trader"
# ─────────────────────────────────────────────────────────────────────────────
func get_label() -> String:
	match item_type:
		Type.FOOD_BONUS:  return "Food(+"  + str(amount) + ")" + ("*" if repeating else "")
		Type.WATER_BONUS: return "Water(+" + str(amount) + ")" + ("*" if repeating else "")
		Type.GOLD_BONUS:  return "Gold(+"  + str(amount) + ")" + ("*" if repeating else "")
		Type.TRADER:      return "Trader"
	return "?"

# ─────────────────────────────────────────────────────────────────────────────
# can_collect() -> bool
# Returns whether the player is currently allowed to pick this item up.
# - Repeating items: blocked if already collected this turn.
# - One-time items:  always collectible (they'll be removed after collection).
# ─────────────────────────────────────────────────────────────────────────────
func can_collect() -> bool:
	if repeating:
		return not collected_this_turn  # Only once per turn for renewables
	return true  # One-time items are always collectable; Player removes them after

# ─────────────────────────────────────────────────────────────────────────────
# reset_turn()
# Called by MapCell.reset_turn() → GameMap.reset_turn() at the start of each
# new turn. Clears the "already collected" flag so repeating items are
# available to collect again.
# ─────────────────────────────────────────────────────────────────────────────
func reset_turn():
	collected_this_turn = false
