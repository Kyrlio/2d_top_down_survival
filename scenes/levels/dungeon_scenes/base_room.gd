extends Node2D

enum DoorDir {
	NONE = 0,
	NORTH = 1,
	EAST = 2,
	SOUTH = 4,
	WEST = 8
}

enum STATE {
	IDLE,
	COMBAT,
	CLEARED
}

@onready var doors: Node2D = $Doors
@onready var door_north: StaticBody2D = $Doors/DoorNorth
@onready var door_east: StaticBody2D = $Doors/DoorEast
@onready var door_south: StaticBody2D = $Doors/DoorSouth
@onready var door_west: StaticBody2D = $Doors/DoorWest

@onready var walls: Node2D = $Walls
@onready var wall_north: StaticBody2D = $Walls/WallNorth
@onready var wall_east: StaticBody2D = $Walls/WallEast
@onready var wall_south: StaticBody2D = $Walls/WallSouth
@onready var wall_west: StaticBody2D = $Walls/WallWest

@onready var fog_mask: TileMapLayer = %FogMask
@onready var vision_area: Area2D = %VisionArea
@onready var fog_of_war: Node2D = $FogOfWar

@onready var spawn_area_2d: Area2D = %SpawnArea2D
@onready var enemy_manager: Node = $EnemyManager


@export var keep_discovered_room_visible: bool = true


var room_type: String = ""
var active_state: STATE = STATE.IDLE
var active_doors_mask: int = 0

func _ready() -> void:
	walls.visible = true
	doors.visible = true
	fog_of_war.visible = true
	vision_area.body_entered.connect(_on_vision_area_body_entered)
	vision_area.body_exited.connect(_on_vision_area_body_exited)
	set_fog_enabled(true)
	call_deferred("_refresh_initial_fog_state")
	spawn_area_2d.body_entered.connect(_on_spawn_area_body_entered)


func setup(mask: int, type: String) -> void:
	room_type = type
	active_doors_mask = mask
	
	# --- GESTION DU NORD ---
	if mask & DoorDir.NORTH != 0:
		# Il y a une porte ! On cache le mur plein et on désactive sa collision
		set_node_active(wall_north, false)
		#set_node_active(door_north, true)
		door_north.visible = false
		door_north.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		# Pas de porte. On affiche le mur plein.
		set_node_active(wall_north, true)
		set_node_active(door_north, false)
	
	# --- GESTION DU L'EST ---
	if mask & DoorDir.EAST != 0:
		set_node_active(wall_east, false)
		#set_node_active(door_east, true)
		door_east.visible = false
		door_east.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		set_node_active(wall_east, true)
		set_node_active(door_east, false)
	
	# --- GESTION DU SUD ---
	if mask & DoorDir.SOUTH != 0:
		set_node_active(wall_south, false)
		#set_node_active(door_south, true)
		door_south.visible = false
		door_south.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		set_node_active(wall_south, true)
		set_node_active(door_south, false)
	
	# --- GESTION DE L'OUEST ---
	if mask & DoorDir.WEST != 0:
		set_node_active(wall_west, false)
		#set_node_active(door_west, true)
		door_west.visible = false
		door_west.process_mode = Node.PROCESS_MODE_DISABLED
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
		for child in node.get_children():
			if child is CollisionShape2D:
				child.disabled = true
			if child is TileMapLayer:
				child.enabled = false
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


func start_combat() -> void:
	active_state = STATE.COMBAT
	
	close_active_doors()
	
	spawn_area_2d.queue_free()
	enemy_manager.begin_round()


func room_cleared() -> void:
	active_state = STATE.CLEARED
	open_active_doors()


func close_active_doors() -> void:
	if active_doors_mask & DoorDir.NORTH != 0:
		door_north.process_mode = Node.PROCESS_MODE_INHERIT
		door_north.visible = true
	if active_doors_mask & DoorDir.EAST != 0:
		door_east.process_mode = Node.PROCESS_MODE_INHERIT
		door_east.visible = true
	if active_doors_mask & DoorDir.SOUTH != 0:
		door_south.process_mode = Node.PROCESS_MODE_INHERIT
		door_south.visible = true
	if active_doors_mask & DoorDir.WEST != 0:
		door_west.process_mode = Node.PROCESS_MODE_INHERIT
		door_west.visible = true


func open_active_doors() -> void:
	if active_doors_mask & DoorDir.NORTH != 0:
		set_node_active.call_deferred(door_north, false)
		#door_north.process_mode = Node.PROCESS_MODE_INHERIT
		#door_north.visible = true
	if active_doors_mask & DoorDir.EAST != 0:
		set_node_active.call_deferred(door_east, false)
		#door_east.process_mode = Node.PROCESS_MODE_INHERIT
		#door_east.visible = true
	if active_doors_mask & DoorDir.SOUTH != 0:
		set_node_active.call_deferred(door_south, false)
		#door_south.process_mode = Node.PROCESS_MODE_INHERIT
		#door_south.visible = true
	if active_doors_mask & DoorDir.WEST != 0:
		set_node_active.call_deferred(door_west, false)
		#door_west.process_mode = Node.PROCESS_MODE_INHERIT
		#door_west.visible = true


func set_fog_enabled(enabled: bool) -> void:
	fog_mask.visible = enabled
	fog_of_war.visible = enabled


func _refresh_initial_fog_state() -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player and vision_area.overlaps_body(player):
		set_fog_enabled(false)


func _on_vision_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(fog_mask, "modulate:a", 0.0, 0.5)
		await tween.finished
		set_fog_enabled(false)


func _on_vision_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not keep_discovered_room_visible:
			fog_mask.modulate.a = 0.0
			set_fog_enabled(true)
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.tween_property(fog_mask, "modulate:a", 1.0, 0.5)


func _on_spawn_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if active_state == STATE.IDLE:
			if room_type == "Start":
				return
			start_combat()


func get_active_state() -> STATE:
	return active_state
