extends Node

@export var rock_scene: PackedScene
@export var spawn_rect: ReferenceRect

var spawn_root: Node2D


func _ready() -> void:
	spawn_root = get_tree().get_first_node_in_group("ysort")


func start_for_room(room_type: String) -> void:
	if room_type == "Start" or room_type == "Boss":
		return
	
	for i in range(2, 5):
		_spawn_rock()


## Get a random position in the spawn rectangle
func get_random_spawn_position() -> Vector2:
	var x = randf_range(0, spawn_rect.size.x)
	var y = randf_range(0, spawn_rect.size.y)
	
	return spawn_rect.global_position + Vector2(x, y)


## Spawn one rock at a random location in the spawn rectangle
func _spawn_rock() -> void:
	var rock = rock_scene.instantiate()
	rock.global_position = get_random_spawn_position()
	rock.z_index = 1
	spawn_root.add_child(rock, true)
