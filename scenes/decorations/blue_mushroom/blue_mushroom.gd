extends Node2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.frame = randi() % 4
