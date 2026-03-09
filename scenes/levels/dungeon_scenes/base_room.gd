extends Node2D

enum DoorDir {
	NONE = 0,
	NORTH = 1,
	EAST = 2,
	SOUTH = 4,
	WEST = 8
}

@onready var door_north: StaticBody2D = $Doors/DoorNorth
@onready var door_east: StaticBody2D = $Doors/DoorEast
@onready var door_south: StaticBody2D = $Doors/DoorSouth
@onready var door_west: StaticBody2D = $Doors/DoorWest

@onready var wall_north: StaticBody2D = $Walls/WallNorth
@onready var wall_east: StaticBody2D = $Walls/WallEast
@onready var wall_south: StaticBody2D = $Walls/WallSouth
@onready var wall_west: StaticBody2D = $Walls/WallWest
@onready var fog_mask: TileMapLayer = $FogMask
@onready var vision_area: Area2D = $VisionArea

@export var keep_discovered_room_visible: bool = true


var room_type: String = ""


func _ready() -> void:
	vision_area.body_entered.connect(_on_vision_area_body_entered)
	vision_area.body_exited.connect(_on_vision_area_body_exited)
	set_fog_enabled(true)
	call_deferred("_refresh_initial_fog_state")


func setup(mask: int, type: String) -> void:
	room_type = type
	
	# --- GESTION DU NORD ---
	if mask & DoorDir.NORTH != 0:
		# Il y a une porte ! On cache le mur plein et on désactive sa collision
		set_node_active(wall_north, false)
		set_node_active(door_north, true)
	else:
		# Pas de porte. On affiche le mur plein.
		set_node_active(wall_north, true)
		set_node_active(door_north, false)
	
	# --- GESTION DU L'EST ---
	if mask & DoorDir.EAST != 0:
		set_node_active(wall_east, false)
		set_node_active(door_east, true)
	else:
		set_node_active(wall_east, true)
		set_node_active(door_east, false)
	
	# --- GESTION DU SUD ---
	if mask & DoorDir.SOUTH != 0:
		set_node_active(wall_south, false)
		set_node_active(door_south, true)
	else:
		set_node_active(wall_south, true)
		set_node_active(door_south, false)
	
	# --- GESTION DE L'OUEST ---
	if mask & DoorDir.WEST != 0:
		set_node_active(wall_west, false)
		set_node_active(door_west, true)
	else:
		set_node_active(wall_west, true)
		set_node_active(door_west, false)
	
	apply_room_type_logic()


## Fonction utilitaire pour activer/désactiver visuellement ET physiquement un nœud
func set_node_active(node: Node, active: bool) -> void:
	# 1. Gère le visuel (Sprite)
	if node is CanvasItem:
		node.visible = active
	
	# 2. Gère la physique (Désactiver le nœud l'empêche de calculer ses collisions)
	if active:
		node.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		node.process_mode = Node.PROCESS_MODE_DISABLED


func apply_room_type_logic() -> void:
	match room_type:
		"Start":
			# Exemple : ne pas spawner d'ennemies
			pass
		"Boss":
			# Exemple : spawn boss
			pass
		"Normal":
			# Exemple : spawner ennemis aléatoire
			pass


func set_fog_enabled(enabled: bool) -> void:
	fog_mask.visible = enabled


func _refresh_initial_fog_state() -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player and vision_area.overlaps_body(player):
		set_fog_enabled(false)


func _on_vision_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		set_fog_enabled(false)


func _on_vision_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not keep_discovered_room_visible:
			set_fog_enabled(true)
