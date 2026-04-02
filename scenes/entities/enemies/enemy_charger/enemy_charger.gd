@icon("uid://47471th1ui0o")
class_name EnemyCharger extends Enemy

enum ChargePhase {
	NONE,
	WINDUP,
	DASH
}

@export_category("Charge")
@export var charge_windup_min: float = 0.5
@export var charge_windup_max: float = 0.75
@export var charge_speed: float = 250.0
@export var charge_duration: float = 0.35
@export var charge_cooldown: float = 4.0

var _charge_phase: ChargePhase = ChargePhase.NONE
var _phase_timer: float = 0.0
var _charge_direction: Vector2 = Vector2.ZERO


func can_start_attack() -> bool:
	return attack_cooldown <= 0.0 and distance_to_player() <= aggro_range / 3 and can_see_player()


func update_facing_direction() -> void:
	if not is_instance_valid(player):
		return
	var player_pos = player.global_position
	visuals.scale = Vector2.ONE if (player_pos - global_position).x >= 0 else Vector2(-1, 1)



# ---------------------------- STATES -----------------------------

func _enter_state_attack() -> void:
	if alert_tween != null and alert_tween.is_valid():
		alert_tween.kill()
	
	alert_sprite.visible = true
	alert_tween = create_tween()
	alert_tween.tween_property(alert_sprite, "scale", Vector2.ONE, .2).set_ease(Tween.EASE_OUT).set_trans(Tween.TransitionType.TRANS_BACK)
	
	attack_cooldown = charge_cooldown
	_charge_phase = ChargePhase.WINDUP
	_phase_timer = randf_range(charge_windup_min, charge_windup_max)
	velocity = Vector2.ZERO

	if animation_player.has_animation("confused"):
		animation_player.play("confused")
	else:
		animation_player.play("idle")



func _update_state_attack(delta: float) -> void:
	match _charge_phase:
		ChargePhase.WINDUP:
			#animation_player.play("charge_attack")
			velocity = Vector2.ZERO
			update_facing_direction()
			_phase_timer -= delta
			
			if _phase_timer <= 0.0:
				if is_instance_valid(player):
					_charge_direction = global_position.direction_to(player.global_position)
				else:
					_charge_direction = Vector2.RIGHT
				
				if _charge_direction.length_squared() <= 0.001:
					_charge_direction = Vector2.RIGHT * sign(visuals.scale.x)
				
				_charge_direction = _charge_direction.normalized()
				_charge_phase = ChargePhase.DASH
				_phase_timer = charge_duration
				animation_player.play("walk")
		
		ChargePhase.DASH:
			hit_area.enabled(true)
			velocity = _charge_direction * charge_speed
			move_and_slide()
			_phase_timer -= delta
			
			if get_slide_collision_count() > 0 or _phase_timer <= 0.0:
				hit_area.enabled(false)
				super.switch_state(STATE.IDLE)
		
		_:
			hit_area.enabled(false)
			super.switch_state(STATE.IDLE)


func exit_attack_state() -> void:
	velocity = Vector2.ZERO
	_charge_phase = ChargePhase.NONE
	_phase_timer = 0.0
	_charge_direction = Vector2.ZERO
	
	if alert_tween != null and alert_tween.is_valid():
		alert_tween.kill()
	
	alert_tween = create_tween()
	alert_tween.tween_property(alert_sprite, "scale", Vector2.ZERO, .2).set_ease(Tween.EASE_IN).set_trans(Tween.TransitionType.TRANS_BACK)
