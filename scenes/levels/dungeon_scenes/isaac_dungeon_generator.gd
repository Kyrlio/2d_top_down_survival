extends Node

const MAX_ROOMS: int = 15
const ROOM_WIDTH: int = 432
const ROOM_HEIGHT: int = 272

enum DoorDir {
	NONE = 0,
	NORTH = 1, # Vector2.UP (0, -1)
	EAST = 2,  # Vector2.RIGHT (1, 0)
	SOUTH = 4, # Vector2.DOWN (0, 1)
	WEST = 8   # Vector2.LEFT (-1, 0)
}

@onready var player: Player = $YSort/Player

@export var room_scene: PackedScene
@export var dungeon_depth: int = 1
#@export var player_scene: PackedScene

var dungeon_grid: Dictionary = {} 
var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var y_sort_node: Node2D

func _ready() -> void:
	generate_dungeon_plan()
	calculate_doors()
	print_dungeon_console()
	#print(dungeon_grid)
	y_sort_node = $YSort
	
	# Build the dungeon
	build_dungeon()
	
	# Spawning Player in the start room
	spawn_player()
	


func generate_dungeon_plan() -> void:
	var start_pos: Vector2 = Vector2.ZERO
	dungeon_grid[start_pos] = {"type": "Start", "distance_from_start": 0}
	
	var rooms_placed: int = 1
	
	while rooms_placed < MAX_ROOMS:
		var current_rooms: Array = dungeon_grid.keys() # positions des pièces placées
		var random_existing_room_pos: Vector2 = current_rooms.pick_random() # choisir une pièce aléatoire
		var random_dir: Vector2 = directions.pick_random() 
		var new_room_pos: Vector2 = random_existing_room_pos + random_dir
		
		if not dungeon_grid.has(new_room_pos):
			var dist: int = dungeon_grid[random_existing_room_pos]["distance_from_start"] + 1
			dungeon_grid[new_room_pos] = {"type": "Normal", "distance_from_start": dist}
			rooms_placed += 1
	
	assign_special_rooms()


## Assign specials room to the dungeon as the Boss room
func assign_special_rooms() -> void:
	var max_dist: int = 0
	var boss_room_pos: Vector2 = Vector2.ZERO
	
	for pos: Vector2 in dungeon_grid.keys():
		var current_dist: int = dungeon_grid[pos]["distance_from_start"]
		if current_dist > max_dist:
			max_dist = current_dist
			boss_room_pos = pos
			
	dungeon_grid[boss_room_pos]["type"] = "Boss"


## Add bitmask to each room. Example if room has north, east, south and west neighbor -> bitmask = 15
func calculate_doors() -> void:
	for pos: Vector2 in dungeon_grid.keys():
		var door_mask: int = DoorDir.NONE
		
		# On vérifie chaque voisin direct. S'il existe dans la grille, on a besoin d'une porte
		
		# Voisin au NORD (Y - 1)
		if dungeon_grid.has(pos + Vector2.UP):
			door_mask |= DoorDir.NORTH # |= ajoute le bit sans écraser les autres
		
		# Voisin à l'EST (X+1)
		if dungeon_grid.has(pos + Vector2.RIGHT):
			door_mask |= DoorDir.EAST
		
		# Voisin au SUD (Y+1)
		if dungeon_grid.has(pos + Vector2.DOWN):
			door_mask |= DoorDir.SOUTH
		
		# Voisin a l'OUEST (X-1)
		if dungeon_grid.has(pos + Vector2.LEFT):
			door_mask |= DoorDir.WEST
		
		dungeon_grid[pos]["door_mask"] = door_mask


func build_dungeon() -> void:
	for pos: Vector2 in dungeon_grid.keys():
		var room_data: Dictionary = dungeon_grid[pos]
		
		# 1. Instancier la scène de la salle
		var room_instance: Node2D = room_scene.instantiate()
		
		# 2. Positionner la salle dans l'espace 2D en multipliant la position de la grille par la taille en pixels
		room_instance.position = Vector2(pos.x * ROOM_WIDTH, pos.y * ROOM_HEIGHT)
		
		# 3. Ajouter la salle à la scène (GameManager ou Hub)
		y_sort_node.add_child(room_instance)
		#add_child(room_instance)
		
		# 4. Transmettre les informations à la salle pour qu'elle s'adapte
		if room_instance.has_method("setup"):
			room_instance.setup(room_data["door_mask"], room_data["type"], dungeon_depth)


func spawn_player() -> void:
	if not player:
		push_error("Player scene not assigned in dungeon generator!")
		return
	
	# Find the start room position
	var start_pos: Vector2 = Vector2.ZERO
	for pos: Vector2 in dungeon_grid.keys():
		if dungeon_grid[pos]["type"] == "Start":
			start_pos = pos
			break
	
	# Position the player at the center of the start room
	player.position = Vector2(
		start_pos.x * ROOM_WIDTH + ROOM_WIDTH * 0.5,
		start_pos.y * ROOM_HEIGHT + ROOM_HEIGHT * 0.5
	)


func print_dungeon_console() -> void:
	if dungeon_grid.is_empty():
		print("Le donjon est vide.")
		return
	
	print("[#] = salle normale")
	print("[B] = salle de boss")
	print("[S] = salle de départ\n")
	
	# 1. Trouver les limites de la grille (Bounding Box)
	var min_x: float = 0.0
	var max_x: float = 0.0
	var min_y: float = 0.0
	var max_y: float = 0.0

	for pos: Vector2 in dungeon_grid.keys():
		if pos.x < min_x: min_x = pos.x
		if pos.x > max_x: max_x = pos.x
		if pos.y < min_y: min_y = pos.y
		if pos.y > max_y: max_y = pos.y

	print("--- Plan du Donjon ---")
	
	# 2. Dessiner la grille de haut en bas, de gauche à droite
	for y: float in range(min_y, max_y + 1):
		var row_string: String = ""
		for x: float in range(min_x, max_x + 1):
			var current_pos: Vector2 = Vector2(x, y)
			
			if dungeon_grid.has(current_pos):
				var type: String = dungeon_grid[current_pos]["type"]
				match type:
					"Start":
						row_string += "[S]"
					"Boss":
						row_string += "[B]"
					_:
						row_string += "[#]" # Salle normale
			else:
				row_string += " . " # Espace vide
				
		print(row_string)
