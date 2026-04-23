extends Node

class_name StartPhase

func startPhase() -> void:
	#play start phase animation
	
	#change gamePhase to decisionPhase
	GameManager.gamePhase = 1
