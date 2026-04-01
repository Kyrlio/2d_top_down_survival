@icon("uid://47471th1ui0o")
class_name Enemy extends CharacterBody2D

signal hit

enum STATE {
	SPAWN,
	IDLE,
	CHASE,
	ATTACK,
	HURT,
	DEAD
}

const CORPSE_SCENE: PackedScene = preload("uid://mwfnfkya6aqp")
const PICK_UP = preload("uid://1atsbj7ft3su")
const COIN = preload("uid://cx1v2d5h66kjh")

@export_category("Stats")
@export var speed: int = 25
@export var attack_damage: int = 10
@export var attack_speed: float = 0.75
@export var aggro_range: float = 300.0
@export var attack_range: float = 25.0
@export var knockback_force: float = 65.0
@export var coin_drop_amount: int = 1 ## Drop between -1 and +2 coins

@export_category("Related Scene")
@export var death_packed: PackedScene
@export var death_sprite: CompressedTexture2D

@onready var spawn_point: Vector2 = global_position
@onready var animation_player: AnimationPlayer = get_node_or_null("%AnimationPlayer")
@onready var hit_gpu_particles: GPUParticles2D = get_node_or_null("%HitGPUParticles")
@onready var damage_spawning_point: Marker2D = get_node_or_null("%DamageSpawningPoint")
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var visuals: Node2D = get_node_or_null("%Visuals")
@onready var hit_area: HitArea2D = get_node_or_null("%HitArea2D")
@onready var navigation_agent: NavigationAgent2D = get_node_or_null("%NavigationAgent2D")
@onready var alert_sprite: Sprite2D = get_node_or_null("%AlertSprite")
@onready var health_component: HealthComponent = get_node_or_null("%HealthComponent")
@onready var health_bar: CustomHealthBar = get_node_or_null("%CustomHealthBar")
@onready var chase_again_timer: Timer = get_node_or_null("%ChaseAgainTimer")


var active_state: STATE = STATE.SPAWN
var pushback_force: Vector2 = Vector2.ZERO
var attack_cooldown: float
var alert_tween: Tween
var is_alerted: bool = false


func _ready() -> void:
	if not _ensure_dependencies():
		set_process(false)
		return
	
	# Enemy Avoidance
	if navigation_agent and not navigation_agent.velocity_computed.is_connected(_on_navigation_agent_2d_velocity_computed):
		navigation_agent.velocity_computed.connect(_on_navigation_agent_2d_velocity_computed)
	
	health_bar.setup_health_bar(health_component.max_health)
	switch_state(STATE.SPAWN)
	if hit_area:
		hit_area.top_level = true
		hit_area.set_damage(attack_damage)
	if alert_sprite:
		alert_sprite.scale = Vector2.ZERO
	
	# Signals
	health_component.died.connect(_died)


func _ensure_dependencies() -> bool:
	# Allow explicit scene wiring and fallback to common node names.
	animation_player = animation_player if animation_player else get_node_or_null("AnimationPlayer")
	hit_gpu_particles = hit_gpu_particles if hit_gpu_particles else get_node_or_null("HitGPUParticles")
	damage_spawning_point = damage_spawning_point if damage_spawning_point else get_node_or_null("DamageSpawningPoint")
	visuals = visuals if visuals else get_node_or_null("Visuals")
	hit_area = hit_area if hit_area else get_node_or_null("HitArea2D")
	navigation_agent = navigation_agent if navigation_agent else get_node_or_null("NavigationAgent2D")
	alert_sprite = alert_sprite if alert_sprite else get_node_or_null("AlertSprite")
	health_component = health_component if health_component else get_node_or_null("HealthComponent")
	health_bar = health_bar if health_bar else get_node_or_null("CustomHealthBar")
	chase_again_timer = chase_again_timer if chase_again_timer else get_node_or_null("ChaseAgainTimer")
	
	var missing: Array[String] = []
	if animation_player == null:
		missing.append("AnimationPlayer")
	if damage_spawning_point == null:
		missing.append("DamageSpawningPoint")
	if visuals == null:
		missing.append("Visuals")
	if navigation_agent == null:
		missing.append("NavigationAgent2D")
	if health_component == null:
		missing.append("HealthComponent")
	if health_bar == null:
		missing.append("CustomHealthBar")
	
	if not missing.is_empty():
		push_error("Enemy missing required nodes: %s" % ", ".join(missing))
		return false
	
	return true


func _process(delta: float) -> void:
	_process_state(delta)
	if hit_area:
		hit_area.global_position = global_position
	
	# Knockback
	pushback_force = lerp(pushback_force, Vector2.ZERO, delta * 10.0)
	if pushback_force.length() > 10.0:
		velocity = pushback_force
		move_and_slide()


func switch_state(to_state: STATE) -> void:
	if active_state == STATE.DEAD:
		return
	
	var previous_state := active_state
	if previous_state == STATE.ATTACK and to_state != STATE.ATTACK:
		exit_attack_state()
	active_state = to_state
	
	if active_state != STATE.CHASE:
		stop_movement()
	
	match active_state:
		STATE.SPAWN: _enter_state_spawn()
		STATE.IDLE: _enter_state_idle(previous_state)
		STATE.CHASE: _enter_state_chase()
		STATE.ATTACK: _enter_state_attack()
		STATE.HURT: _enter_state_hurt()
		STATE.DEAD: _enter_state_dead()


func _process_state(delta: float) -> void:
	match active_state:
		STATE.IDLE: _update_state_idle(delta)
		STATE.CHASE: _update_state_chase(delta)
		STATE.ATTACK: _update_state_attack(delta)
		STATE.HURT: _update_state_hurt(delta)
		STATE.DEAD: _update_state_dead(delta)


func _enter_state_spawn() -> void:
	var tween := create_tween()
	tween.tween_property(visuals, "scale", Vector2.ONE, 0.4).from(Vector2.ZERO).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.finished.connect(func ():
		switch_state(STATE.IDLE)
	)


func _enter_state_idle(_previous_state: STATE) -> void:
	alert_sprite.scale = Vector2.ZERO
	animation_player.play("idle")


func _enter_state_chase() -> void:
	animation_player.play("walk")

	if alert_tween != null and alert_tween.is_valid():
		alert_tween.kill()

	if not is_alerted and alert_sprite:
		alert_tween = create_tween()
		alert_tween.tween_property(alert_sprite, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TransitionType.TRANS_BACK)
		alert_tween.tween_interval(0.2)
		alert_tween.chain().tween_property(alert_sprite, "scale", Vector2.ZERO, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TransitionType.TRANS_BACK)
		is_alerted = true


func _enter_state_attack() -> void:
	push_warning("Enemy : enter_state_attack need override")
	pass


func _enter_state_hurt() -> void:
	if animation_player.is_playing():
		animation_player.stop()
	animation_player.play("hit")
	GameCamera.shake(1)


func _enter_state_dead() -> void:
	animation_player.play("death")
	health_bar.visible = false
	
	# Désactive les collisions pour que le corps (et son hitbox) soit inerte
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	if hit_area:
		hit_area.enabled.call_deferred(false)
		
	# On spawne immédiatement le cadavre au sol et les particules
	spawn_death_particles()
	#spawn_corpse.call_deferred()
	
	var die_tween := create_tween()
	die_tween.tween_property(visuals, "scale", Vector2.ZERO, .5).set_ease(Tween.EASE_IN).set_trans(Tween.TransitionType.TRANS_BACK)
	
	await die_tween.finished
	await drop_loot()
	
	# Et on supprime définitivement l'ennemi
	queue_free()


func _update_state_idle(delta: float) -> void:
	update_attack_cooldown(delta)
	if can_start_attack():
		switch_state(STATE.ATTACK)
	elif distance_to_player() <= aggro_range:
		switch_state(STATE.CHASE)


func _update_state_chase(delta: float) -> void:
	update_facing_direction()
	update_attack_cooldown(delta)
	if is_instance_valid(player):
		move(player.global_position)
	if can_start_attack():
		switch_state(STATE.ATTACK)
	if PlayerManager.is_player_dead == true:
		switch_state(STATE.IDLE)


func _update_state_attack(_delta: float) -> void:
	push_warning("Enemy : update_state_attack need override")
	pass


func _update_state_hurt(_delta: float) -> void:
	if not animation_player.is_playing():
		switch_state(STATE.IDLE)


func _update_state_dead(_delta: float) -> void:
	velocity = Vector2.ZERO


func distance_to_player() -> float:
	if not is_instance_valid(player):
		return INF
	var distance: float = global_position.distance_to(player.global_position)
	return distance


func can_start_attack() -> bool:
	return attack_cooldown <= 0.0 and distance_to_player() <= attack_range and can_see_player()


func enter_attack_state() -> void:
	attack_cooldown = attack_speed


func process_attack_state(_delta: float) -> void:
	switch_state(STATE.IDLE)


func exit_attack_state() -> void:
	pass


func take_damage(amount: int) -> void:
	call_deferred("switch_state", STATE.HURT)
	hit.emit()
	GameEvents.emit_engine_freeze()
	
	health_component.take_damage(amount)
	
	var label: Control = preload("uid://cdnp6bhgi0oys").instantiate()
	label.position = damage_spawning_point.position
	add_child(label)
	label.set_damage(amount)
	
	health_bar.change_value(health_component.current_health)


func _died():
	GameEvents.emit_enemy_died()
	switch_state(STATE.DEAD)
	

func knock_back(source_position: Vector2, power: float = 1.0) -> void:
	if hit_gpu_particles:
		hit_gpu_particles.rotation = get_angle_to(source_position) + PI
	var effective_knockback = (knockback_force + randi() % 15 - 3) * power
	pushback_force = - global_position.direction_to(source_position) * effective_knockback


func update_facing_direction() -> void:
	if not is_instance_valid(player):
		return
	var player_pos = player.global_position
	visuals.scale = Vector2.ONE if (player_pos - global_position).x >= 0 else Vector2(-1, 1)
	if hit_area:
		hit_area.look_at(player_pos)


func update_attack_cooldown(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta


func move(target_position: Vector2) -> void:
	navigation_agent.target_position = target_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	
	var desired_velocity = global_position.direction_to(next_path_position) * speed
	
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(desired_velocity)
	else:
		velocity = desired_velocity
		move_and_slide()


func stop_movement() -> void:
	velocity = Vector2.ZERO
	if navigation_agent and navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(Vector2.ZERO)


func spawn_death_particles() -> void:
	if not death_packed:
		return
		
	var die_particles: Node2D = death_packed.instantiate()
	die_particles.global_position = global_position
	
	var target_parent: Node2D = get_tree().get_first_node_in_group("ysort")
	if not target_parent:
		target_parent = get_parent()
	target_parent.add_child(die_particles)


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if active_state != STATE.CHASE:
		return
	
	#navigation_agent.velocity = safe_velocity
	velocity = safe_velocity
	move_and_slide()


func can_see_player() -> bool:
	if not is_instance_valid(player):
		return false
	var space_state = get_world_2d().direct_space_state
	# Check collision with Environment (Layer 3 -> value 4)
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position, 4)
	var result = space_state.intersect_ray(query)
	
	# If we hit something in the Environment layer, we can't see the player clearly enough to attack
	if result:
		return false
	return true


func drop_loot() -> void:
	var random_amount := coin_drop_amount + randi_range(-1, 2)
	random_amount = max(1, random_amount)
	
	var parent_node := get_parent()
	
	# Créer un pick_up individuel pour chaque morceau de bois
	for i in range(random_amount):
		# Créer le slot_data pour un seul morceau de bois
		var slot_data := SlotData.new()
		slot_data.item_data = COIN
		slot_data.quantity = 1
		
		# Instancier le pick_up
		var pick_up = PICK_UP.instantiate()
		pick_up.slot_data = slot_data
		pick_up.global_position = global_position
		
		parent_node.add_child(pick_up)
		
		var angle_offset := (TAU / random_amount) * i
		var random_variation := randf_range(-0.5, 0.5)
		var final_angle := angle_offset + random_variation
		var direction := Vector2(cos(final_angle), sin(final_angle))
		
		var launch_speed := randf_range(25.0, 50.0)
		
		# Décale légèrement chaque pièce par un interval constant (par ex. 0.05s) au lieu de faire gonfler le timer exponentiellement !
		if i > 0:
			await get_tree().create_timer(0.05).timeout
			
		if pick_up.has_method("launch"):
			pick_up.launch(direction, launch_speed)


func spawn_corpse() -> void:
	var corpse := CORPSE_SCENE.instantiate()
	if corpse:
		corpse.corpse_sprite = death_sprite
		if corpse is RigidBody2D:
			(corpse as RigidBody2D).global_position = global_position
			(corpse as RigidBody2D).linear_velocity = velocity
		else:
			(corpse as Node2D).global_position = global_position
		#var target_parent: Node2D = Level.corpse_layer if Level.corpse_layer else get_parent()
		var target_parent: Node2D = get_tree().get_first_node_in_group("ysort")
		if target_parent:
			target_parent.add_child(corpse)



func get_active_state() -> STATE:
	return active_state
