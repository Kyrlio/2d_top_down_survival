@icon("uid://ddeuvhb74snum")
class_name HitArea2D extends Area2D

@export var damage: int = 10
var knockback_power: float = 1.0
var cshape: CollisionShape2D

func _ready() -> void:
	if get_child_count() <= 0:
		push_error("HitArea2D.gd : need a CollisionShape2D")
	cshape = get_child(0)


func get_damage() -> int:
	return damage + randi() % 6 - 2


func set_damage(amount: int) -> void:
	damage = amount

func enabled(enabled: bool) -> void:
	monitorable = enabled
	monitoring = enabled
	cshape.disabled = !enabled
