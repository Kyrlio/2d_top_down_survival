@icon("uid://47471th1ui0o")
class_name Enemy extends CharacterBody2D

signal hit

enum STATE {
	IDLE,
	CHASE,
	CONFUSED,
	RETURN,
	ATTACK,
	HURT,
	DEAD
}

const CORPSE_SCENE: PackedScene = preload("uid://mwfnfkya6aqp")

@export_category("Stats")
@export var speed: int = 25
@export var attack_damage: int = 10
@export var attack_speed: float = 0.75
@export var hitpoints: int = 180
@export var aggro_range: float = 100.0
@export var attack_range: float = 25.0
@export var knockback_force: float = 65.0

@export_category("Related Scene")
@export var death_packed: PackedScene
@export var death_sprite: CompressedTexture2D

@onready var spawn_point: Vector2 = global_position
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hit_gpu_particles: GPUParticles2D = %HitGPUParticles
@onready var damage_spawning_point: Marker2D = %DamageSpawningPoint
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var visuals: Node2D = %Visuals
@onready var hit_area: HitArea2D = %HitArea2D
@onready var navigation_agent: NavigationAgent2D = %NavigationAgent2D
@onready var alert_sprite: Sprite2D = $AlertSprite
@onready var health_component: HealthComponent = %HealthComponent
@onready var health_bar: CustomHealthBar = %CustomHealthBar


var active_state: STATE = STATE.IDLE
var pushback_force: Vector2 = Vector2.ZERO
var attack_cooldown: float
var alert_tween: Tween
var is_alerted: bool = false


func _ready() -> void:
	health_bar.setup_health_bar(health_component.max_health)
	_switch_state(STATE.IDLE)
	hit_area.top_level = true
	alert_sprite.scale = Vector2.ZERO
	
	# Signals
	health_component.died.connect(_died)


func _process(delta: float) -> void:
	_process_state(delta)
	hit_area.global_position = global_position
	pushback_force = lerp(pushback_force, Vector2.ZERO, delta * 10.0)
	velocity = pushback_force
	
	move_and_slide()


func _switch_state(to_state: STATE) -> void:
	if active_state == STATE.DEAD:
		return
	
	var previous_state := active_state
	active_state = to_state
	
	match active_state:
		STATE.IDLE:
			animation_player.play("idle")
			if previous_state == STATE.RETURN:
				is_alerted = false
		
		STATE.CHASE:
			animation_player.play("walk")
			
			if alert_tween != null and alert_tween.is_valid():
				alert_tween.kill()
			
			if not is_alerted:
				alert_tween = create_tween()
				alert_tween.tween_property(alert_sprite, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TransitionType.TRANS_BACK)
				alert_tween.tween_interval(0.2)
				alert_tween.chain().tween_property(alert_sprite, "scale", Vector2.ZERO, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TransitionType.TRANS_BACK)
				is_alerted = true
		
		STATE.CONFUSED:
			animation_player.play("confused")
		
		STATE.RETURN:
			animation_player.play("walk")
		
		STATE.ATTACK:
			animation_player.play("attack")
			attack_cooldown = attack_speed
		
		STATE.HURT:
			if animation_player.is_playing():
				animation_player.stop()
			animation_player.play("hit")
			GameCamera.shake(1)
		
		STATE.DEAD:
			health_bar.visible = false
			animation_player.call_deferred("stop")
			animation_player.call_deferred("play", "death")


func _process_state(delta: float) -> void:
	match active_state:
		STATE.IDLE:
			update_attack_cooldown(delta)
			if distance_to_player() <= attack_range and attack_cooldown <= 0.0 and can_see_player():
				_switch_state(STATE.ATTACK)
			elif distance_to_player() <= aggro_range:
				_switch_state(STATE.CHASE)
		
		STATE.CHASE:
			update_facing_direction()
			update_attack_cooldown(delta)
			move(player.global_position)
			if distance_to_player() <= attack_range and attack_cooldown <= 0.0 and can_see_player():
				_switch_state(STATE.ATTACK)
			if distance_to_player() > aggro_range * 1.5:
				_switch_state(STATE.CONFUSED)
			if Gamedata.is_player_dead == true:
				_switch_state(STATE.CONFUSED)
		
		STATE.CONFUSED:
			await animation_player.animation_finished
			_switch_state(STATE.RETURN)
		
		STATE.RETURN:
			update_facing_direction()
			update_attack_cooldown(delta)
			move(spawn_point)
			if global_position.distance_to(spawn_point) < 2.0:
				_switch_state(STATE.IDLE)
		
		STATE.ATTACK:
			if not animation_player.is_playing():
				_switch_state(STATE.IDLE)
		
		STATE.HURT:
			if not animation_player.is_playing():
				_switch_state(STATE.IDLE)
		
		STATE.DEAD:
			velocity = Vector2.ZERO


func distance_to_player() -> float:
	var distance: float = global_position.distance_to(player.global_position)
	return distance


func take_damage(amount: int) -> void:
	call_deferred("_switch_state", STATE.HURT)
	hit.emit()
	
	health_component.take_damage(amount)
	
	var label: Control = preload("uid://cdnp6bhgi0oys").instantiate()
	label.position = damage_spawning_point.position
	add_child(label)
	label.set_damage(amount)
	
	health_bar.change_value(health_component.current_health)


func _died():
	_switch_state(STATE.DEAD)
	

func knock_back(source_position: Vector2, power: float = 1.0) -> void:
	hit_gpu_particles.rotation = get_angle_to(source_position) + PI
	var effective_knockback = (knockback_force + randi() % 15 - 3) * power
	pushback_force = - global_position.direction_to(source_position) * effective_knockback


func update_facing_direction() -> void:
	if active_state == STATE.RETURN:
		visuals.scale = Vector2.ONE if (spawn_point - global_position).x >= 0 else Vector2(-1, 1)
	else:
		var player_pos = player.global_position
		visuals.scale = Vector2.ONE if (player_pos - global_position).x >= 0 else Vector2(-1, 1)
		hit_area.look_at(player_pos)


func update_attack_cooldown(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta


func move(target_position: Vector2) -> void:
	navigation_agent.target_position = target_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	velocity = global_position.direction_to(next_path_position) * speed
	
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity_forced(velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(velocity)
	move_and_slide()


func spawn_death_particles() -> void:
	var die_particles: Node2D = death_packed.instantiate()
	die_particles.global_position = get_parent().global_position
	
	#var background_node: Node = Main.background_effects
	#if not is_instance_valid(background_node):
		#background_node = get_parent()
	#background_node.add_child(die_particles)


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	navigation_agent.velocity = safe_velocity


func can_see_player() -> bool:
	var space_state = get_world_2d().direct_space_state
	# Check collision with Environment (Layer 3 -> value 4)
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position, 4)
	var result = space_state.intersect_ray(query)
	
	# If we hit something in the Environment layer, we can't see the player clearly enough to attack
	if result:
		return false
	return true


func spawn_corpse() -> void:
	var corpse := CORPSE_SCENE.instantiate()
	if corpse:
		corpse.corpse_sprite = death_sprite
		if corpse is RigidBody2D:
			(corpse as RigidBody2D).global_position = global_position
			(corpse as RigidBody2D).linear_velocity = velocity
		else:
			(corpse as Node2D).global_position = global_position
		var target_parent: Node2D = Main.corpse_layer if Main.corpse_layer else get_parent()
		if target_parent:
			target_parent.add_child(corpse)
