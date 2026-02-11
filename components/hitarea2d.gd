@icon("uid://ddeuvhb74snum")
class_name HitArea2D extends Area2D

@export var damage: int = 10
var knockback_power: float = 1.0

func get_damage() -> int:
	return damage + randi() % 6 - 2


func set_damage(amount: int) -> void:
	damage = amount
