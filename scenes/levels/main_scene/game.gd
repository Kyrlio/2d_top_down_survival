class_name Game extends Node2D

signal loading_finished

const PICK_UP = preload("uid://1atsbj7ft3su")

static var corpse_layer: Node2D

@export var freeze_slow := 0.06
@export var freeze_time := 0.15

@onready var inventory_interface: Control = %InventoryInterface
@onready var hot_bar_inventory: PanelContainer = %HotBarInventory
@onready var level_container: Node2D = $LevelContainer

var player: Player
var loading_finished_emitted := false
var y_sort: Node2D
var hub_scene_instance: Node
var is_in_hub: bool = true


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	y_sort = get_tree().get_first_node_in_group("ysort")
	
	hub_scene_instance = level_container.get_child(0)
	
	GameEvents.engine_freeze_requested.connect(freeze_engine)
	GameEvents.dungeon_entered_requested.connect(go_to_dungeon)
	
	# Player Inventory
	_bind_player_inventory(player)
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.set_equip_inventory_data(player.equip_inventory_data)
	inventory_interface.force_close.connect(_on_inventory_toggled)
	hot_bar_inventory.set_inventory_data(player.inventory_data)
	
	# External inventory (chests)
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(_on_inventory_toggled)
	
	call_deferred("_emit_loading_finished")


func _emit_loading_finished() -> void:
	if loading_finished_emitted:
		return
	loading_finished_emitted = true
	loading_finished.emit()


func request_loading_finished() -> void:
	if loading_finished_emitted:
		return
	call_deferred("_emit_loading_finished")


func has_loading_finished() -> bool:
	return loading_finished_emitted


func freeze_engine() -> void:
	Engine.time_scale = freeze_slow
	await get_tree().create_timer(freeze_time * freeze_slow).timeout
	Engine.time_scale = 1.0


func go_to_dungeon() -> void:
	print("going to dungeon !")
	is_in_hub = false
	level_container.remove_child.call_deferred(hub_scene_instance)
	
	var dungeon_scene = preload("uid://w5eetrwr448i").instantiate()
	
	level_container.add_child.call_deferred(dungeon_scene)
	call_deferred("_refresh_runtime_bindings")


func return_to_hub() -> void:
	print("Going to hub !")
	is_in_hub = true
	var current_dungeon = level_container.get_child(0)
	current_dungeon.queue_free()
	
	level_container.add_child(hub_scene_instance)
	call_deferred("_refresh_runtime_bindings")


func _bind_player_inventory(new_player: Player) -> void:
	if not new_player:
		return

	if player and player != new_player and player.toggle_inventory.is_connected(_on_inventory_toggled):
		player.toggle_inventory.disconnect(_on_inventory_toggled)

	player = new_player

	if not player.toggle_inventory.is_connected(_on_inventory_toggled):
		player.toggle_inventory.connect(_on_inventory_toggled)


func _refresh_runtime_bindings() -> void:
	await get_tree().process_frame
	var active_player := get_tree().get_first_node_in_group("player") as Player
	_bind_player_inventory(active_player)
	y_sort = get_tree().get_first_node_in_group("ysort") as Node2D


func _on_inventory_toggled(external_inventory_owner = null) -> void:
	inventory_interface.visible = not inventory_interface.visible
	
	if inventory_interface.visible:
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hot_bar_inventory.hide()
	else:
		#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		hot_bar_inventory.show()
	
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()


func _on_inventory_interface_drop_slot_data(slot_data: SlotData) -> void:
	var pick_up = PICK_UP.instantiate()
	
	if is_in_hub:
		pick_up.z_index = 0
	
	pick_up.slot_data = slot_data
	var start_pos := player.get_drop_position()
	pick_up.global_position = start_pos

	if not y_sort or not y_sort.is_inside_tree():
		y_sort = get_tree().get_first_node_in_group("ysort") as Node2D

	if y_sort and y_sort.is_inside_tree():
		y_sort.add_child(pick_up)
	else:
		# Fallback to avoid losing dropped item if YSort is temporarily unavailable.
		level_container.add_child(pick_up)
	
	if pick_up.has_method("launch"):
		pick_up.launch(player.get_effective_aim(), 50.0)
