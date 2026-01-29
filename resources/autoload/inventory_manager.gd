extends Node

signal inventory_updated

const INVENTORY_SIZE = 20


var inventory: Array[ItemData] = []


func _ready() -> void:
	inventory.resize(INVENTORY_SIZE)

## Add a item to the inventory.
## Return true if the item is added false otherwise
func add_item(item: ItemData) -> bool:
	# Check first free space
	for i in range(inventory.size()):
		if inventory[i] == null:
			inventory[i] = item
			inventory_updated.emit() # Notify the UI
			return true
	return false


## Swap items in the inventory
func swap_items(index_from: int, index_to: int) -> void:
	var temp := inventory[index_to]
	inventory[index_to] = inventory[index_from]
	inventory[index_from] = temp
	inventory_updated.emit()
