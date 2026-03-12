extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var door_open: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_door_open(false)


func set_door_open(toggle: bool) -> void:
	door_open = toggle
	sprite.visible = not toggle
	collision_shape.disabled = toggle

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		set_door_open(not door_open)
