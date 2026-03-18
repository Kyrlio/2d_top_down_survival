class_name DungeonEntrance extends Area2D



func _on_body_entered(body: Node2D) -> void:
	GameEvents.emit_dungeon_entered()
