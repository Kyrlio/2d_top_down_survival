extends Control

@export var gravity := Vector2(0, 750)

var velocity := Vector2.ZERO

@onready var label: Label = $Label


func _ready() -> void:
	velocity = Vector2(randf_range(-100, 100), -100)


func _process(delta: float) -> void:
	velocity += gravity * delta
	position += velocity * delta


func set_damage(amount: int) -> void:
	label.text = str(-absi(amount))
