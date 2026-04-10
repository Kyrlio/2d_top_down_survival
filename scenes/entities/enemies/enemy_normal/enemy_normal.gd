@icon("uid://47471th1ui0o")
class_name EnemyNormal extends Enemy


func _enter_state_attack() -> void:
	animation_player.play("attack")
	attack_cooldown = attack_speed


func _update_state_attack(_delta: float) -> void:
	# Force physics update if hit_area exists
	if hit_area and animation_player.current_animation_position > 0.2 and animation_player.current_animation_position < 0.4:
		hit_area.enabled(true)
	elif hit_area:
		hit_area.enabled(false)
		
	if not animation_player.is_playing():
		super.switch_state(STATE.IDLE)
