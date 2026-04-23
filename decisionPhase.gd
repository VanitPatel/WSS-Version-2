extends Node

# ─────────────────────────────────────────────────────────────────────────────
# decisionPhase.gd  (STUB / LEGACY)
# Originally intended to house the logic for the "decision phase" — the moment
# each turn where the player (or AI) chooses what to do next.
#
# This has been completely replaced by:
#   • Brain.make_move()       – AI picks a direction each turn
#   • GameManager._do_turn()  – orchestrates the turn sequence
#   • Player.do_turn()        – executes the chosen move
#
# This file is kept to avoid scene-loading errors on any nodes that still
# reference it.  It has no active behaviour.
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	pass  # No initialisation needed

func _process(delta: float) -> void:
	pass  # All decision logic is handled by Brain / GameManager
