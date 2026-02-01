extends PanelContainer

signal hot_bar_use(index: int)

const SLOT = preload("uid://8ymnewlyixe4")


@onready var h_box_container: HBoxContainer = $MarginContainer/HBoxContainer


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed():
		return
	
	# Vérifier les actions d'input plutôt que les keycodes directs
	# Cela fonctionne avec AZERTY et QWERTY
	for i in range(6):
		var action_name = "hot_bar_%d" % (i + 1)
		if Input.is_action_just_pressed(action_name):
			hot_bar_use.emit(i)
			get_tree().root.set_input_as_handled()


func set_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.connect(populate_hot_bar)
	populate_hot_bar(inventory_data)
	hot_bar_use.connect(inventory_data.use_slot_data)


func populate_hot_bar(inventory_data: InventoryData) -> void:
	for child in h_box_container.get_children():
		child.queue_free()
	
	for slot_data in inventory_data.slot_datas.slice(0, 6):
		var slot = SLOT.instantiate()
		h_box_container.add_child(slot)
		
		if slot_data:
			slot.set_slot_data(slot_data)
