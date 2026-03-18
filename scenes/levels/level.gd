class_name Level extends Node2D

static var corpse_layer: Node2D

@export var freeze_slow := 0.06
@export var freeze_time := 0.15

@onready var enemies: Node2D = %Enemies
@onready var navigation_layer: TileMapLayer = $Tilemap/NavigationLayer
@onready var _corpse_layer: Node2D = %CorpseLayer
@onready var y_sort: Node2D = %YSort

var player: Player
var loading_finished_emitted := false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	corpse_layer = _corpse_layer
	
	if navigation_layer != null:
		navigation_layer.visible = false
