class_name Main extends Node2D

const PICK_UP = preload("uid://1atsbj7ft3su")


static var corpse_layer: Node2D

@export var freeze_slow := 0.06
@export var freeze_time := 0.15

@onready var enemies: Node2D = %Enemies
@onready var navigation_layer: TileMapLayer = $Tilemap/NavigationLayer
@onready var _corpse_layer: Node2D = %CorpseLayer
@onready var y_sort: Node2D = %YSort
@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/HotBarInventory

var player: Player


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	corpse_layer = _corpse_layer
	
	if navigation_layer != null:
		navigation_layer.visible = false
		
	for enemy: CharacterBody2D in enemies.get_children():
		if enemy.has_signal("hit"):
			enemy.hit.connect(freeze_engine)
	if player.has_signal("hit"):
		player.hit.connect(freeze_engine)
		
	# Player Inventory
	player.toggle_inventory.connect(_on_inventory_toggled)
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.set_equip_inventory_data(player.equip_inventory_data)
	inventory_interface.force_close.connect(_on_inventory_toggled)
	hot_bar_inventory.set_inventory_data(player.inventory_data)
	
	# External inventory (chests)
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(_on_inventory_toggled)


func freeze_engine() -> void:
	Engine.time_scale = freeze_slow
	await get_tree().create_timer(freeze_time * freeze_slow).timeout
	Engine.time_scale = 1.0


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
	pick_up.slot_data = slot_data
	var start_pos := player.get_drop_position()
	pick_up.global_position = start_pos
	y_sort.add_child(pick_up)
	#if pick_up.has_method("play_drop_animation"):
		#pick_up.play_drop_animation(target_pos, start_pos)
	
	if pick_up.has_method("launch"):
		pick_up.launch(player.get_effective_aim(), 50.0)
