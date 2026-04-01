@icon("uid://47471th1ui0o")
class_name EnemyNormal extends Enemy

func _enter_state_attack() -> void:
	animation_player.play("attack")
	attack_cooldown = attack_speed


func _update_state_attack(_delta: float) -> void:
	if not animation_player.is_playing():
		super.switch_state(STATE.IDLE)
