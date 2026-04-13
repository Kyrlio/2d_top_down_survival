extends Node

@export_group("Blue Mushroom")
@export var blue_mushroom_scene: PackedScene
@export var min_blue_mushroom_elements: int = 0
@export var max_blue_mushroom_elements: int = 6

@export_group("Red Mushroom")
@export var red_mushroom_scene: PackedScene
@export var min_red_mushroom_elements: int = 0
@export var max_red_mushroom_elements: int = 5

@export_group("Torches")
@export var torch_scene: PackedScene
@export var min_torch_elements: int = 0
@export var max_torch_elements: int = 3

@export_group("Graves")
@export var grave_scene: PackedScene
@export var min_graves_elements: int = 0
@export var max_graves_elements: int = 10

@export var spawn_rect: ReferenceRect

var spawn_root: Node2D


func _ready() -> void:
	# DecorationManager est enfant de la room; la room est enfant du YSort du donjon actif.
	spawn_root = get_parent().get_parent() as Node2D if get_parent() else null
	if not spawn_root:
		push_error("DecorationManager could not resolve a local spawn root")
		spawn_root = get_parent() as Node2D


func spawn_mushrooms() -> void:
	for i in range(0, get_random_number(min_red_mushroom_elements, max_red_mushroom_elements)):
		_spawn_decoration(red_mushroom_scene)
	
	for i in range(0, get_random_number(min_blue_mushroom_elements, max_blue_mushroom_elements)):
		_spawn_decoration(blue_mushroom_scene)


func spawn_torches() -> void:
	for i in range(0, get_random_number(min_torch_elements, max_torch_elements)):
		_spawn_decoration(torch_scene)


func spawn_graves() -> void:
	for i in range(0, get_random_number(min_graves_elements, max_graves_elements)):
		_spawn_decoration(grave_scene)


func get_random_number(min_elements: int, max_elements: int) -> int:
	return randi() % max_elements + min_elements


## Get a random position in the spawn rectangle
func get_random_spawn_position() -> Vector2:
	var x = randf_range(0, spawn_rect.size.x)
	var y = randf_range(0, spawn_rect.size.y)
	
	return spawn_rect.global_position + Vector2(x, y)


## Spawn one rock at a random location in the spawn rectangle
func _spawn_decoration(scene: PackedScene) -> void:
	var decoration = scene.instantiate() as Node2D
	decoration.global_position = get_random_spawn_position()
	decoration.z_index = 1
	
	spawn_root.add_child(decoration, true)
