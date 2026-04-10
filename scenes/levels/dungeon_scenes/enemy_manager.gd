extends Node

signal room_completed

enum STATE {
	IDLE,
	COMBAT,
	CLEARED
}

@export var enemies_scenes: Array[PackedScene]
@export var spawn_rect: ReferenceRect
@export var number_enemy_by_room: int = 5

@export_group("Depth Scaling")
@export var enemies_per_depth: int = 1
@export var extra_rolls_per_depth: int = 1
@export var health_multiplier_per_depth: float = 0.2
@export var damage_multiplier_per_depth: float = 0.12
@export var speed_multiplier_per_depth: float = 0.03
@export var cooldown_multiplier_per_depth: float = 0.03
@export var loot_bonus_per_depth: int = 1

@onready var base_room: Node2D = $".."

var active_enemies: Array[Enemy] = []
var enemy_spawn_root: Node2D
var current_depth: int = 1


func _ready() -> void:
	enemy_spawn_root = get_tree().get_first_node_in_group("ysort")
	room_completed.connect(_on_room_completed)


func begin_round(depth: int = 1) -> void:
	current_depth = max(1, depth)
	active_enemies.clear()
	var depth_bonus := current_depth - 1
	var min_count := number_enemy_by_room + depth_bonus * enemies_per_depth
	var max_count := min_count + 2 + depth_bonus * extra_rolls_per_depth
	for i in randi_range(min_count, max_count):
		spawn_enemy.call_deferred()
		await get_tree().create_timer(0.01).timeout


## Get a random position in the spawn rectangle
func get_random_spawn_position() -> Vector2:
	var x = randf_range(0, spawn_rect.size.x)
	var y = randf_range(0, spawn_rect.size.y)
	
	return spawn_rect.global_position + Vector2(x, y)


## Spawn one enemy at a random location in the spawn rectangle
func spawn_enemy() -> void:
	var enemy_chosen = enemies_scenes.pick_random()
	var enemy = enemy_chosen.instantiate() as Enemy
	_apply_depth_scaling(enemy)
	enemy.global_position = get_random_spawn_position()
	enemy.z_index = 1
	var health_component := enemy.get_node_or_null("HealthComponent") as HealthComponent
	if health_component:
		health_component.died.connect(_on_specific_enemy_died.bind(enemy))
	active_enemies.append(enemy)
	enemy_spawn_root.add_child(enemy, true)


func _apply_depth_scaling(enemy: Enemy) -> void:
	var depth_bonus := current_depth - 1
	if depth_bonus <= 0:
		return
	
	var hp_multiplier := 1.0 + depth_bonus * health_multiplier_per_depth
	var damage_multiplier := 1.0 + depth_bonus * damage_multiplier_per_depth
	var speed_multiplier := 1.0 + depth_bonus * speed_multiplier_per_depth
	var cooldown_multiplier := 1.0 - depth_bonus * cooldown_multiplier_per_depth
	
	enemy.speed = maxi(1, int(round(enemy.speed * speed_multiplier)))
	enemy.attack_damage = maxi(1, int(round(enemy.attack_damage * damage_multiplier)))
	enemy.coin_drop_amount = maxi(1, enemy.coin_drop_amount + depth_bonus * loot_bonus_per_depth)
	
	
	if enemy is EnemyJumper:
		enemy.jump_cooldown = min(4.0, float(enemy.jump_cooldown * cooldown_multiplier))
		#print("jumper : ", enemy.jump_cooldown)
	elif enemy is EnemyCharger:
		enemy.charge_cooldown = min(3.0, float(enemy.charge_cooldown * cooldown_multiplier))
		#print("charger : ", enemy.charge_cooldown)
	elif enemy is EnemyShooter:
		enemy.attack_speed = min(0.75, float(enemy.attack_speed * cooldown_multiplier))
		#print("shooter : ", enemy.attack_speed)
	
	var health_component := enemy.get_node_or_null("HealthComponent") as HealthComponent
	if health_component:
		health_component.max_health = maxi(1, int(round(health_component.max_health * hp_multiplier)))
		health_component.current_health = health_component.max_health
	
	var hit_area := enemy.get_node_or_null("Visuals/HandPivot/HitArea2D") as HitArea2D
	if hit_area:
		hit_area.set_damage(enemy.attack_damage)


## Check if the room is completed (all enemies are dead) and emit the signal
func check_room_completed() -> void:
	if active_enemies.is_empty() and get_parent().get_active_state() == STATE.COMBAT:
		room_completed.emit()


func _on_specific_enemy_died(enemy: Enemy) -> void:
	# If actual room is not in combat, return
	if get_parent().get_active_state() != STATE.COMBAT:
		return
	 
	if active_enemies.has(enemy):
		active_enemies.erase(enemy)
		check_room_completed()


func _on_room_completed() -> void:
	get_parent().room_cleared()
