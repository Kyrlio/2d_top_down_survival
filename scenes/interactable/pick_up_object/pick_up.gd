extends Area2D

@export var slot_data: SlotData

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.texture = slot_data.item_data.texture


func _on_area_entered(area: Area2D) -> void:
	if area.owner.inventory_data.pick_up_slot_data(slot_data):
		queue_free()
