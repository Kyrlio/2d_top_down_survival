extends Area2D



func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	GameEvents.emit_return_to_hub()
