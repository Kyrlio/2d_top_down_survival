class_name EquipmentSlot extends ItemSlot

signal equipment_changed(stats: Dictionary)

@export_enum("WEAPON", "TOOL", "ARMOR") var equipment_type: int


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is Control and data.item != null:
		return data.item.item_type == equipment_type
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	super._drop_data(at_position, data)
	
	if item:
		emit_signal("equipment_changed", item.stats)
