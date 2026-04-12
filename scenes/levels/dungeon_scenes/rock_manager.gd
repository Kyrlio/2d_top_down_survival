extends Node

@export var rock_scene: PackedScene
@export var spawn_rect: ReferenceRect

var spawn_root: Node2D


func _ready() -> void:
	spawn_root = get_tree().get_first_node_in_group("ysort")


func start_for_room(room_type: String, depth: int = 1) -> void:
	if room_type == "Start" or room_type == "Boss":
		return
	
	for i in randi_range(0, 5):
		_spawn_rock(depth)


## Get a random position in the spawn rectangle
func get_random_spawn_position() -> Vector2:
	var x = randf_range(0, spawn_rect.size.x)
	var y = randf_range(0, spawn_rect.size.y)
	
	return spawn_rect.global_position + Vector2(x, y)


func _get_random_mineral_for_depth(depth: int) -> String:
	var pool: Array[Dictionary] = []
	
	# Base percentages that change with depth
	var depth_bonus = depth - 1
	var diamond_chance = 1 + depth_bonus * 2
	var gold_chance = 4 + depth_bonus * 3
	var iron_chance = 20 + depth_bonus * 2
	var coal_chance = 20 + depth_bonus * 1
	var rock_chance = max(5, 100 - (diamond_chance + gold_chance + iron_chance + coal_chance))
	
	pool.append({"mineral": "Diamond", "weight": diamond_chance})
	pool.append({"mineral": "Gold", "weight": gold_chance})
	pool.append({"mineral": "Iron", "weight": iron_chance})
	pool.append({"mineral": "Coal", "weight": coal_chance})
	pool.append({"mineral": "Rock", "weight": rock_chance})
	
	var total_weight := 0
	for item in pool:
		total_weight += item["weight"] as int
		
	var random_val := randi() % total_weight
	var current_weight := 0
	
	for item in pool:
		current_weight += item["weight"] as int
		if random_val < current_weight:
			return item["mineral"] as String
			
	return "Rock"

## Spawn one rock at a random location in the spawn rectangle
func _spawn_rock(depth: int) -> void:
	var rock = rock_scene.instantiate() as Rock
	rock.mineral = _get_random_mineral_for_depth(depth)
	rock.global_position = get_random_spawn_position()
	rock.z_index = 1
	spawn_root.add_child(rock, true)
