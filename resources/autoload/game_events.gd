extends Node

signal enemy_died


func emit_enemy_died() -> void:
	enemy_died.emit()
