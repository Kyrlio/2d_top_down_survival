extends Node

signal room_completed

enum STATE {
	IDLE,
	COMBAT,
	CLEARED
}

@export var enemies_scenes: Array[PackedScene]
@export var spawn_rect: ReferenceRect

@onready var base_room: Node2D = $".."

var spawned_enemies: int
var enemy_spawn_root: Node2D


func _ready() -> void:
	enemy_spawn_root = get_tree().get_first_node_in_group("ysort")
	GameEvents.enemy_died.connect(_on_enemy_died)
	room_completed.connect(_on_room_completed)


func begin_round() -> void:
	for i in randi_range(5, 10):
		spawn_enemy.call_deferred()
		await get_tree().create_timer(0.1).timeout


## Get a random position in the spawn rectangle
func get_random_spawn_position() -> Vector2:
	var x = randf_range(0, spawn_rect.size.x)
	var y = randf_range(0, spawn_rect.size.y)
	
	return spawn_rect.global_position + Vector2(x, y)


## Spawn one enemy at a random location in the spawn rectangle
func spawn_enemy() -> void:
	var enemy_chosen = enemies_scenes.pick_random()
	var enemy = enemy_chosen.instantiate() as Enemy
	enemy.global_position = get_random_spawn_position()
	enemy_spawn_root.add_child(enemy, true)
	spawned_enemies += 1


## Check if the room is completed (all enemies are dead) and emit the signal
func check_room_completed() -> void:
	if spawned_enemies <= 0 and get_parent().get_active_state() == STATE.COMBAT:
		room_completed.emit()


func _on_enemy_died() -> void:
	spawned_enemies -= 1
	check_room_completed()


func _on_room_completed() -> void:
	print("ROOM COMPLETED")
	get_parent().room_cleared()
