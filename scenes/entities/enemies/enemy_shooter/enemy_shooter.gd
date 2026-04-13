@icon("uid://47471th1ui0o")
class_name EnemyShooter extends Enemy

@export_category("Shooter")
@export var retreat_range: float = 120.0
@export var shooter_attack_range: float = 250.0
@export var projectile_scene: PackedScene = preload("res://scenes/entities/enemies/enemy_projectile/enemy_projectile.tscn")

var _attack_timer: float = 0.0



func can_start_attack() -> bool:
	var dist = distance_to_player()
	# Permet au Shooter d'attaquer même s'il est en train de fuir
	return attack_cooldown <= 0.0 and dist <= shooter_attack_range and can_see_player()


func _update_state_chase(delta: float) -> void:
	update_facing_direction()
	update_attack_cooldown(delta)
	
	if not is_instance_valid(player):
		return
		
	var dist = distance_to_player()
	
	if dist < retreat_range:
		# Fuit le joueur (le pathfinding va chercher un chemin vers le point opposé)
		var retreat_direction = (global_position - player.global_position).normalized()
		move(global_position + retreat_direction * 150.0)
	elif dist > shooter_attack_range:
		# Se rapproche du joueur
		move(player.global_position)
	else:
		# Dans la zone de tir, s'arrête
		stop_movement()
		
	if can_start_attack():
		switch_state(STATE.ATTACK)
		
	if PlayerManager.is_player_dead == true:
		switch_state(STATE.IDLE)


# ---------------------------- STATES -----------------------------
func _enter_state_idle(previous_state: STATE) -> void:
	# Appelle explicitement le comportement IDLE parent
	super._enter_state_idle(previous_state)


func _update_state_idle(delta: float) -> void:
	# Met à jour le timer cooldown
	update_attack_cooldown(delta)
	
	if can_start_attack():
		switch_state(STATE.ATTACK)
	elif distance_to_player() <= aggro_range:
		switch_state(STATE.CHASE)


func _enter_state_attack() -> void:
	if alert_tween != null and alert_tween.is_valid():
		alert_tween.kill()
	
	if alert_sprite:
		alert_sprite.visible = true
		alert_tween = create_tween()
		alert_tween.tween_property(alert_sprite, "scale", Vector2.ONE, .2).set_ease(Tween.EASE_OUT).set_trans(Tween.TransitionType.TRANS_BACK)
	
	attack_cooldown = attack_speed
	velocity = Vector2.ZERO
	_attack_timer = 0.4 # Force l'état d'attaque pendant au moins 0.4s
	
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	# Tire le projectile
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func():
		if is_instance_valid(self) and active_state == STATE.ATTACK:
			shoot_projectile()
	)


func shoot_projectile() -> void:
	if not projectile_scene or not is_instance_valid(player):
		return
		
	var proj = projectile_scene.instantiate() as Node2D
	var spawn_pos = global_position
	var hand_pivot = get_node_or_null("%HandPivot")
	if hand_pivot:
		spawn_pos = hand_pivot.global_position
		
	proj.global_position = spawn_pos
	if "direction" in proj:
		proj.direction = spawn_pos.direction_to(player.global_position)
	if "damage" in proj:
		proj.damage = attack_damage
		
	var target_parent = get_parent()
	if not target_parent:
		target_parent = get_parent()
		
	target_parent.add_child(proj)


func _update_state_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	update_facing_direction()
	
	_attack_timer -= delta
	if _attack_timer <= 0.0 and (not animation_player.is_playing() or animation_player.current_animation != "attack"):
		super.switch_state(STATE.IDLE)


func exit_attack_state() -> void:
	velocity = Vector2.ZERO
	
	if alert_tween != null and alert_tween.is_valid():
		alert_tween.kill()
	
	if alert_sprite:
		alert_tween = create_tween()
		alert_tween.tween_property(alert_sprite, "scale", Vector2.ZERO, .2).set_ease(Tween.EASE_IN).set_trans(Tween.TransitionType.TRANS_BACK)
