class_name Main extends Node2D

static var corpse_layer: Node2D

@export var freeze_slow := 0.06
@export var freeze_time := 0.15

@onready var enemies: Node2D = %Enemies
@onready var navigation_layer: TileMapLayer = $Tilemap/NavigationLayer
@onready var _corpse_layer: Node2D = %CorpseLayer
@onready var inventory_interface: Control = $UI/InventoryInterface

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
	
	# External inventory (chests)
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(_on_inventory_toggled)


func freeze_engine() -> void:
	Engine.time_scale = freeze_slow
	await get_tree().create_timer(freeze_time * freeze_slow).timeout
	Engine.time_scale = 1.0


func _on_inventory_toggled(external_inventory_owner = null) -> void:
	inventory_interface.visible = not inventory_interface.visible
	
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()
