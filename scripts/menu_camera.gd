extends Camera2D

const DEFAULT_ZOOM: Vector2 = Vector2(1,1)

var anchor_pos: Vector2 = Vector2.ZERO:
	set(value):
		anchor_pos = value
		global_position = value

func _ready() -> void:
	zoom = DEFAULT_ZOOM

func _process(delta: float) -> void:
	global_position = lerp(global_position, (get_global_mouse_position() / 40) + anchor_pos, 0.1)
