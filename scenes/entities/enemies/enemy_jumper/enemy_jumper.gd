@icon("uid://47471th1ui0o")
class_name EnemyJumper extends Enemy

enum ChargePhase {
	NONE,
	WINDUP,
	JUMP,
	LANDING
}

@export_category("Jump")
@export var jump_windup_min: float = 0.5
@export var jump_windup_max: float = 0.75
@export var jump_speed: float = 250.0
@export var jump_height: float = 30.0
@export var jump_cooldown: float = 4.0

@onready var hit_collision_shape: CollisionShape2D = $Visuals/HandPivot/HitArea2D/CollisionShape2D


var _charge_phase: ChargePhase = ChargePhase.NONE
var _phase_timer: float = 0.0
var _charge_direction: Vector2 = Vector2.ZERO
var _target_jump_position: Vector2 = Vector2.ZERO
var _jump_start_position: Vector2 = Vector2.ZERO
var _jump_duration: float = 0.1


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
	
	attack_cooldown = jump_cooldown
	_charge_phase = ChargePhase.WINDUP
	_phase_timer = randf_range(jump_windup_min, jump_windup_max)
	velocity = Vector2.ZERO
	
	animation_player.play("charge_attack")



func _update_state_attack(delta: float) -> void:
	match _charge_phase:
		ChargePhase.WINDUP:
			velocity = Vector2.ZERO
			update_facing_direction()
			_phase_timer -= delta
			
			if _phase_timer <= 0.0:
				if is_instance_valid(player):
					_target_jump_position = player.global_position
				else:
					_target_jump_position = global_position
				
				_jump_start_position = global_position
				_charge_phase = ChargePhase.JUMP
				_jump_duration = max(0.1, _jump_start_position.distance_to(_target_jump_position) / jump_speed)
				_phase_timer = _jump_duration
				animation_player.play("RESET")
		
		ChargePhase.JUMP:
			hit_area.enabled(false)
			_phase_timer -= delta
			var progress = 1.0 - (_phase_timer / _jump_duration)
			if progress > 1.0:
				progress = 1.0
			
			var jump_velocity = (_target_jump_position - _jump_start_position) / _jump_duration
			velocity = jump_velocity
			move_and_slide()
			
			visuals.position.y = - (sin(progress * PI) * jump_height)
			
			if _phase_timer <= 0.0:
				visuals.position.y = 0.0
				_charge_phase = ChargePhase.LANDING
				_phase_timer = 0.15 # Time to keep attack hitbox active
				animation_player.play("attack")
				hit_collision_shape.scale = Vector2(2, 2) # Increase size for AoE effect
				
		ChargePhase.LANDING:
			if _phase_timer > 0.0:
				hit_area.enabled(true)
				_phase_timer -= delta
				
			velocity = Vector2.ZERO
			
			# Wait for the landing animation to finish before returning to IDLE
			if not animation_player.is_playing() or animation_player.current_animation != "attack":
				#hit_area.enabled(false)
				hit_collision_shape.scale = Vector2.ONE
				super.switch_state(STATE.IDLE)
		
		_:
			if hit_area:
				#hit_area.enabled(false)
				hit_collision_shape.scale = Vector2.ONE
			visuals.position.y = 0.0
			super.switch_state(STATE.IDLE)


func exit_attack_state() -> void:
	velocity = Vector2.ZERO
	_charge_phase = ChargePhase.NONE
	_phase_timer = 0.0
	_charge_direction = Vector2.ZERO
	if visuals:
		visuals.position.y = 0.0
	if hit_area:
		#hit_area.enabled(false)
		hit_collision_shape.scale = Vector2.ONE
	
	if alert_tween != null and alert_tween.is_valid():
		alert_tween.kill()
	
	if alert_sprite:
		alert_tween = create_tween()
		alert_tween.tween_property(alert_sprite, "scale", Vector2.ZERO, .2).set_ease(Tween.EASE_IN).set_trans(Tween.TransitionType.TRANS_BACK)
