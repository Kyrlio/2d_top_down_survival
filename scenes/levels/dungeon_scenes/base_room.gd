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
@onready var rock_manager: Node = $RockManager
@onready var spawn_rect: ReferenceRect = $SpawnArea/SpawnRect
@onready var return_to_hub_portal: Area2D = $ReturnToHub
@onready var go_deeper_portal: Area2D = $GoDeeper


@export var keep_discovered_room_visible: bool = true


var room_type: String = ""
var active_state: STATE = STATE.IDLE
var active_doors_mask: int = 0
var dungeon_depth: int = 1

const ROOM_CENTER_LOCAL := Vector2(208, 128)
const PORTAL_MARGIN := 24.0
const MIN_DIST_FROM_PLAYER := 56.0
const MIN_DIST_FROM_CENTER := 72.0
const MIN_DIST_BETWEEN_PORTALS := 96.0
const PORTAL_SPAWN_MAX_ATTEMPTS := 50

func _ready() -> void:
	walls.visible = true
	doors.visible = true
	fog_of_war.visible = true
	set_fog_enabled(true)
	_set_boss_portals_enabled(false)
	call_deferred("_refresh_initial_fog_state")
	
	vision_area.body_entered.connect(_on_vision_area_body_entered)
	vision_area.body_exited.connect(_on_vision_area_body_exited)
	spawn_area_2d.body_entered.connect(_on_spawn_area_body_entered)


func setup(mask: int, type: String, depth: int = 1) -> void:
	room_type = type
	dungeon_depth = max(1, depth)
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
			_setup_start_room()
		"Boss":
			_setup_boss_room()
		"Normal":
			_setup_normal_room()


func _setup_start_room() -> void:
	_set_boss_portals_enabled(false)
	pass


func _setup_boss_room() -> void:
	_set_boss_portals_enabled(false)
	pass


func _setup_normal_room() -> void:
	_set_boss_portals_enabled(false)
	# Spawning rocks in the room
	rock_manager.start_for_room(room_type, dungeon_depth)


func start_combat() -> void:
	active_state = STATE.COMBAT
	
	close_active_doors()
	
	spawn_area_2d.queue_free()
	enemy_manager.begin_round(dungeon_depth)


func room_cleared() -> void:
	active_state = STATE.CLEARED
	open_active_doors()

	if room_type == "Boss":
		_spawn_boss_portals()


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


func _set_boss_portals_enabled(enabled: bool) -> void:
	for portal in [return_to_hub_portal, go_deeper_portal]:
		portal.visible = enabled
		portal.set_deferred("monitoring", enabled)
		portal.set_deferred("monitorable", enabled)


func _spawn_boss_portals() -> void:
	var first_pos := _find_valid_portal_position([])
	if first_pos == Vector2.INF:
		first_pos = ROOM_CENTER_LOCAL + Vector2(-100, 0)

	var second_pos := _find_valid_portal_position([first_pos])

	# Fallback if constraints are too strict in one frame.
	if second_pos == Vector2.INF:
		second_pos = first_pos + Vector2(MIN_DIST_BETWEEN_PORTALS, 0)

	return_to_hub_portal.position = first_pos
	go_deeper_portal.position = second_pos
	_set_boss_portals_enabled(true)


func _find_valid_portal_position(existing_positions: Array[Vector2]) -> Vector2:
	var playable_rect := Rect2(spawn_rect.position + Vector2(PORTAL_MARGIN, PORTAL_MARGIN), spawn_rect.size - Vector2(PORTAL_MARGIN * 2.0, PORTAL_MARGIN * 2.0))
	var center_global := to_global(ROOM_CENTER_LOCAL)
	var player := get_tree().get_first_node_in_group("player") as Node2D

	for _i in PORTAL_SPAWN_MAX_ATTEMPTS:
		var candidate := Vector2(
			randf_range(playable_rect.position.x, playable_rect.position.x + playable_rect.size.x),
			randf_range(playable_rect.position.y, playable_rect.position.y + playable_rect.size.y)
		)

		var candidate_global := to_global(candidate)

		if player and candidate_global.distance_to(player.global_position) < MIN_DIST_FROM_PLAYER:
			continue

		if candidate_global.distance_to(center_global) < MIN_DIST_FROM_CENTER:
			continue

		var too_close := false
		for existing in existing_positions:
			if candidate.distance_to(existing) < MIN_DIST_BETWEEN_PORTALS:
				too_close = true
				break

		if too_close:
			continue

		return candidate

	# Deterministic fallback positions near room corners.
	var fallback_candidates: Array[Vector2] = [
		playable_rect.position,
		Vector2(playable_rect.position.x + playable_rect.size.x, playable_rect.position.y),
		Vector2(playable_rect.position.x, playable_rect.position.y + playable_rect.size.y),
		playable_rect.position + playable_rect.size
	]

	for candidate in fallback_candidates:
		var candidate_global := to_global(candidate)
		if player and candidate_global.distance_to(player.global_position) < MIN_DIST_FROM_PLAYER:
			continue
		if candidate_global.distance_to(center_global) < MIN_DIST_FROM_CENTER:
			continue
		var ok := true
		for existing in existing_positions:
			if candidate.distance_to(existing) < MIN_DIST_BETWEEN_PORTALS:
				ok = false
				break
		if ok:
			return candidate

	return Vector2.INF
