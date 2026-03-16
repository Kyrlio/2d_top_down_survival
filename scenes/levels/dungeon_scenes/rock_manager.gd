extends Node

@export var rock_scene: PackedScene
@export var spawn_rect: ReferenceRect

var spawn_root: Node2D


func _ready() -> void:
	spawn_root = get_tree().get_first_node_in_group("ysort")
	for i in range(2, 5):
		spawn_rock()


## Get a random position in the spawn rectangle
func get_random_spawn_position() -> Vector2:
	var x = randf_range(0, spawn_rect.size.x)
	var y = randf_range(0, spawn_rect.size.y)
	
	return spawn_rect.global_position + Vector2(x, y)


## Spawn one rock at a random location in the spawn rectangle
func spawn_rock() -> void:
	var rock = rock_scene.instantiate()
	rock.global_position = get_random_spawn_position()
	spawn_root.add_child(rock, true)
