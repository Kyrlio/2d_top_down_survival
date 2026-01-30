extends Node

var player
var is_player_dead: bool = false

func use_slot_data(slot_data: SlotData) -> void:
	if slot_data and slot_data.item_data:
		slot_data.item_data.use(player)
	else:
		player.equip_hand()


func get_global_position() -> Vector2:
	return player.global_position
