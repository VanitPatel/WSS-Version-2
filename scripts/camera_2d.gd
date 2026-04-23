extends Camera2D

# ─────────────────────────────────────────────────────────────────────────────
# camera_2d.gd
# A simple auto-panning camera used on the main menu background.
# The camera slowly travels right across the procedurally generated world,
# bounces off the right edge, then travels left, and repeats indefinitely.
# This gives the main menu a living, scrolling backdrop without any input.
#
# Note: During gameplay the camera is repositioned every frame by
# gameboard.gd._center_camera_on_player() to follow the player, so this
# auto-pan script is only active on the main menu scene.
# ─────────────────────────────────────────────────────────────────────────────

# Movement speed in pixels per second (editable in the Godot Inspector)
@export var speed: float = 500.0

# Current travel direction: +1 = moving right (east), -1 = moving left (west)
var _dir: int = 1

func _process(delta: float) -> void:
	# Move the camera horizontally by speed * direction this frame
	position.x += speed * _dir * delta

	# Reverse direction when the camera hits the right boundary
	if position.x >= 4784:
		_dir = -1
	# Reverse direction when the camera hits the left boundary
	elif position.x <= 16:
		_dir = 1
