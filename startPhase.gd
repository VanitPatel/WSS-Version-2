extends Node

class_name StartPhase

# ─────────────────────────────────────────────────────────────────────────────
# startPhase.gd  (STUB / LEGACY)
# Originally intended to drive an animated start phase before gameplay begins
# (e.g. a camera pan, intro cutscene, or countdown).
#
# Currently this script does nothing — startPhase() immediately advances the
# game phase counter and returns.  No animation is played.
#
# To implement an intro sequence, add your animation / tween logic inside
# startPhase() before the line that updates GameManager.gamePhase.
# ─────────────────────────────────────────────────────────────────────────────

func startPhase() -> void:
	# TODO: play start-phase animation here (tween, cutscene, countdown, etc.)

	# Signal to GameManager that the start phase is complete.
	# gamePhase == 1 means "decision phase" is now active.
	GameManager.gamePhase = 1
