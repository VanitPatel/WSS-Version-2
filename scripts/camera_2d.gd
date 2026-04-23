extends Camera2D

@export var speed: float = 500.0

var _dir: int = 1   # 1 = right, -1 = left

func _process(delta: float) -> void:
	position.x += speed * _dir * delta
	# Bounce between x=16 and x=4784
	if position.x >= 4784:
		_dir = -1
	elif position.x <= 16:
		_dir = 1
