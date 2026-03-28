extends Node

var player: Player
var is_player_dead: bool = false

func use_slot_data(slot_data: SlotData) -> void:
	player = get_tree().get_first_node_in_group("player")
	if slot_data and slot_data.item_data:
		slot_data.item_data.use(player)
	else:
		player.equip_hand()


func get_global_position() -> Vector2:
	player = get_tree().get_first_node_in_group("player")
	return player.global_position
