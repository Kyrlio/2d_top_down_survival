class_name Enemy extends Node2D

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hp_progress_bar: ProgressBar = %HPProgressBar


func take_damage(amount: int) -> void:
	hp_progress_bar.value = max(0, hp_progress_bar.value - amount)
	if hp_progress_bar.value == 0:
		queue_free()
	if animation_player.is_playing():
		animation_player.stop()
	animation_player.play("hit")
