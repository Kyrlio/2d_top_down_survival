extends StaticBody2D

signal toggle_inventory(external_inventory_owner)

@export var inventory_data: InventoryData

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var can_interact: bool = false
var is_open: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact") and can_interact:
			open_chest()
			toggle_inventory.emit(self)


func open_chest() -> void:
	if is_open:
		close_chest()
	else:
		is_open = true
		animation_player.play("open")


func close_chest() -> void:
	is_open = false
	animation_player.play("closed")
