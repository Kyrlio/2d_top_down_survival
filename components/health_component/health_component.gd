@icon("uid://cf2q1nbwyffvh")
class_name HealthComponent extends Node2D

signal died
signal health_changed(current_health: int, max_health: int)

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var ground_particles_scene: PackedScene

@export var max_health: int = 50

var _current_health: int
var current_health: int:
	get:
		return _current_health
	set(value):
		if value == _current_health:
			return
		_current_health = value
		health_changed.emit(_current_health, max_health)


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int):
	current_health = clamp(current_health - amount, 0, max_health)
	play_hit_sfx()
	print(current_health)
	if current_health == 0:
		died.emit()


func play_hit_sfx():
	pass
