extends Node

signal enemy_died
signal engine_freeze_requested
signal dungeon_entered_requested


func emit_enemy_died() -> void:
	enemy_died.emit()


func emit_engine_freeze() -> void:
	engine_freeze_requested.emit()


func emit_dungeon_entered() -> void:
	dungeon_entered_requested.emit()
