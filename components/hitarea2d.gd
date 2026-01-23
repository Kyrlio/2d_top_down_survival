@icon("uid://ddeuvhb74snum")
class_name HitArea2D extends Area2D

@export var damage: int = 10


func get_damage() -> int:
	return damage + randi() % 7 - 3
