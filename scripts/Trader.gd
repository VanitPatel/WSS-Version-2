extends RefCounted
class_name Trader

# ─────────────────────────────────────────────────────────────────────────────
# Trader.gd
# Implements a negotiating NPC the player can encounter on the map.
# Trading is a multi-round back-and-forth: the player makes an offer,
# the Trader either accepts, counters, or walks away.
#
# NOTE: The Trader class is fully implemented but not yet wired into the
# main game loop. Currently, Player._collect_item() performs a simplified
# auto-trade (1 gold → 2 water) when it lands on a TRADER item.
# This class is ready to be integrated for a richer trading UI later.
#
# Three personality presets are available via static factory methods:
#   make_patient()  – 5 rounds, fair terms
#   make_stubborn() – 3 rounds, demands more
#   make_eager()    – 8 rounds, accepts poor deals
# ─────────────────────────────────────────────────────────────────────────────

# ── State machine ─────────────────────────────────────────────────────────────
# Tracks where the negotiation stands after each player action.
enum State {
	READY,      # No offer has been made yet; waiting for the player to propose
	COUNTERED,  # Trader rejected the player's offer and made a counter-offer
	ACCEPTED,   # A deal was struck; apply the trade then dismiss the trader
	REJECTED    # Trader walked away; no more trading this encounter
}

var state: State       = State.READY  # Current negotiation phase
var offer_count: int   = 0            # Number of player offers made so far this encounter
var max_offers:  int                  # Maximum offers before the trader gives up
var patience:    int                  # Stubbornness factor (higher = demands better deal)
var name_label:  String               # Trader's display name shown in messages

# The active offer sitting on the table from the trader's side.
# Keys: give_gold, give_water, give_food (what trader gives the player)
#        want_gold, want_water, want_food (what trader wants from the player)
var trader_offer: Dictionary = {}

# ─────────────────────────────────────────────────────────────────────────────
# Constructor
# trader_name : Display name for this NPC (e.g. "Old Trapper")
# max_off     : Maximum rounds of negotiation before the trader walks away
# pat         : Patience/stubbornness (used to evaluate whether an offer is good)
# ─────────────────────────────────────────────────────────────────────────────
func _init(trader_name: String, max_off: int, pat: int):
	name_label = trader_name
	max_offers = max_off
	patience   = pat

# ─────────────────────────────────────────────────────────────────────────────
# player_offer(...) -> Dictionary
# The player proposes a trade: they offer some resources and request others.
# Returns a result dict: { "state": State, "message": String, "offer": Dictionary }
#
# Parameters (all non-negative integers):
#   give_gold/water/food – what the player is willing to hand over
#   want_gold/water/food – what the player wants in return
#
# Valuation heuristic (simple point system):
#   gold = 3 pts, water = 2 pts, food = 2 pts
# The trader accepts if give_val >= want_val * (patience / 10).
# A patience of 10 means an exactly equal trade is required.
# A patience of 5 means the trader accepts half-value offers (eager).
# ─────────────────────────────────────────────────────────────────────────────
func player_offer(give_gold: int, give_water: int, give_food: int,
				  want_gold: int,  want_water: int,  want_food: int) -> Dictionary:

	# Guard: once a deal is done or the trader left, no more negotiation
	if state == State.REJECTED or state == State.ACCEPTED:
		return {"state": state, "message": name_label + " is no longer trading.", "offer": {}}

	offer_count += 1

	# Trader quits after too many rounds of back-and-forth
	if offer_count > max_offers:
		state = State.REJECTED
		return {"state": state, "message": name_label + " is frustrated and walks away!", "offer": {}}

	# Calculate point value of what the player is giving vs. requesting
	var give_val = give_gold * 3 + give_water * 2 + give_food * 2
	var want_val = want_gold * 3 + want_water * 2 + want_food * 2

	# Accept if the player's offer is generous enough relative to patience
	if give_val >= want_val * patience / 10:
		state = State.ACCEPTED
		trader_offer = {
			"give_gold": want_gold, "give_water": want_water, "give_food": want_food,
			"want_gold": give_gold, "want_water": give_water, "want_food": give_food
		}
		return {"state": state, "message": name_label + " accepts your offer!", "offer": trader_offer}

	# Reject but make a counter-offer: ask for 20% more than the player offered
	var counter_want_val = int(give_val * 1.2)
	var cw = min(want_water + 1, counter_want_val / 2)  # Ask for slightly more water
	var cf = want_food   # Keep food demand the same
	var cg = want_gold   # Keep gold demand the same

	state = State.COUNTERED
	trader_offer = {
		"give_gold": want_gold, "give_water": want_water, "give_food": want_food,
		"want_gold": cg,        "want_water": cw,         "want_food": cf
	}
	var msg = (name_label + " counter-offers: give " +
		str(cg) + "g/" + str(cw) + "w/" + str(cf) + "f  for  " +
		str(want_gold) + "g/" + str(want_water) + "w/" + str(want_food) + "f")
	return {"state": state, "message": msg, "offer": trader_offer}

# ─────────────────────────────────────────────────────────────────────────────
# player_accepts() -> Dictionary
# Player accepts whatever counter-offer is currently on the table.
# Returns the finalised deal so the caller can apply the resource transfer.
# ─────────────────────────────────────────────────────────────────────────────
func player_accepts() -> Dictionary:
	if trader_offer.is_empty():
		return {"state": State.REJECTED, "message": "No offer on the table.", "offer": {}}
	state = State.ACCEPTED
	return {"state": state, "message": name_label + " shakes on it.", "offer": trader_offer}

# ─────────────────────────────────────────────────────────────────────────────
# player_rejects() -> Dictionary
# Player walks away from the negotiation entirely.
# ─────────────────────────────────────────────────────────────────────────────
func player_rejects() -> Dictionary:
	state = State.REJECTED
	return {"state": state, "message": name_label + " nods and steps aside.", "offer": {}}

# ─────────────────────────────────────────────────────────────────────────────
# reset()
# Resets this trader back to its initial ready state for a fresh encounter.
# ─────────────────────────────────────────────────────────────────────────────
func reset():
	state        = State.READY
	offer_count  = 0
	trader_offer = {}

# ─────────────────────────────────────────────────────────────────────────────
# Static factory methods
# Each creates a Trader with a different negotiation personality.
# ─────────────────────────────────────────────────────────────────────────────

# Patient merchant: up to 5 rounds, accepts fair or better deals (patience 8)
static func make_patient() -> Trader:
	return Trader.new("Merchant", 5, 8)

# Stubborn trapper: only 3 rounds, demands better terms (patience 12)
static func make_stubborn() -> Trader:
	return Trader.new("Old Trapper", 3, 12)

# Eager nomad: up to 8 rounds, accepts even poor deals (patience 5)
static func make_eager() -> Trader:
	return Trader.new("Friendly Nomad", 8, 5)
