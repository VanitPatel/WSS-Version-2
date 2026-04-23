extends RefCounted
class_name Trader

# Trader state machine
enum State {
	READY,       # Waiting for a player offer
	COUNTERED,   # Trader made a counter-offer
	ACCEPTED,    # Trade accepted
	REJECTED     # Trader walked away
}

var state: State = State.READY
var offer_count: int = 0
var max_offers: int   # How many rounds before trader quits (varies by type)
var patience: int     # How stubborn the trader is (affects counter quality)
var name_label: String

# Current standing offer from the trader side
var trader_offer: Dictionary = {}  # {give_gold, give_water, give_food, want_gold, want_water, want_food}

func _init(trader_name: String, max_off: int, pat: int):
	name_label   = trader_name
	max_offers   = max_off
	patience     = pat

# Player proposes: give {gold,water,food}, want {gold,water,food}
# Returns a result dict: {state, message, offer}
func player_offer(give_gold: int, give_water: int, give_food: int,
				  want_gold: int,  want_water: int,  want_food: int) -> Dictionary:

	if state == State.REJECTED or state == State.ACCEPTED:
		return {"state": state, "message": name_label + " is no longer trading.", "offer": {}}

	offer_count += 1

	# Check if trader quits due to too many rounds
	if offer_count > max_offers:
		state = State.REJECTED
		return {"state": state, "message": name_label + " is frustrated and walks away!", "offer": {}}

	# Evaluate the trade value (simple heuristic: water=2pts, food=2pts, gold=3pts)
	var give_val = give_gold * 3 + give_water * 2 + give_food * 2
	var want_val = want_gold * 3 + want_water * 2 + want_food * 2

	# If player's offer is generous enough, accept
	if give_val >= want_val * patience / 10:
		state = State.ACCEPTED
		trader_offer = {
			"give_gold": want_gold, "give_water": want_water, "give_food": want_food,
			"want_gold": give_gold, "want_water": give_water, "want_food": give_food
		}
		return {
			"state": state,
			"message": name_label + " accepts your offer!",
			"offer": trader_offer
		}

	# Otherwise, counter-offer: trader asks for slightly more
	var counter_want_val = int(give_val * 1.2)
	var cw = min(want_water + 1, counter_want_val / 2)
	var cf = want_food
	var cg = want_gold

	state = State.COUNTERED
	trader_offer = {
		"give_gold": want_gold, "give_water": want_water, "give_food": want_food,
		"want_gold": cg, "want_water": cw, "want_food": cf
	}
	var msg = (name_label + " counter-offers: give " +
		str(cg) + "g/" + str(cw) + "w/" + str(cf) + "f  for  " +
		str(want_gold) + "g/" + str(want_water) + "w/" + str(want_food) + "f")
	return {"state": state, "message": msg, "offer": trader_offer}

# Player accepts the standing trader_offer
func player_accepts() -> Dictionary:
	if trader_offer.is_empty():
		return {"state": State.REJECTED, "message": "No offer on the table.", "offer": {}}
	state = State.ACCEPTED
	return {"state": state, "message": name_label + " shakes on it.", "offer": trader_offer}

# Player rejects
func player_rejects() -> Dictionary:
	state = State.REJECTED
	return {"state": state, "message": name_label + " nods and steps aside.", "offer": {}}

func reset():
	state       = State.READY
	offer_count = 0
	trader_offer = {}

# --- Factory methods for different trader personalities ---

static func make_patient() -> Trader:
	# Will negotiate up to 5 rounds, accepts fair deals
	return Trader.new("Merchant", 5, 8)

static func make_stubborn() -> Trader:
	# Only 3 rounds, demands better terms
	return Trader.new("Old Trapper", 3, 12)

static func make_eager() -> Trader:
	# Many rounds, accepts poor deals — very generous
	return Trader.new("Friendly Nomad", 8, 5)
