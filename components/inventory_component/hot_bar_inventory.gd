extends PanelContainer

signal hot_bar_use(index: int)

const SLOT = preload("uid://8ymnewlyixe4")

var selected_slot_index: int = -1

@onready var h_box_container: HBoxContainer = $MarginContainer/HBoxContainer


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed():
		return
	
	# Vérifier les actions d'input plutôt que les keycodes directs
	# Cela fonctionne avec AZERTY et QWERTY
	for slot_index in range(6):
		var action_name = "hot_bar_%d" % (slot_index + 1)
		if Input.is_action_just_pressed(action_name):
			selected_slot_index = slot_index  # Sauvegarder d'abord
			hot_bar_use.emit(slot_index)
			# Appliquer la sélection après que populate_hot_bar ait recréé les slots
			call_deferred("_apply_selection_visual", slot_index)
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
	
	# Réappliquer la sélection après repopulation (différé car queue_free n'est pas immédiat)
	if selected_slot_index >= 0:
		call_deferred("_apply_selection_visual", selected_slot_index)


func _apply_selection_visual(index: int) -> void:
	var all_children = h_box_container.get_children()
	var slots: Array = []
	
	# Filtrer les slots qui ne sont pas en cours de suppression
	for child in all_children:
		if not child.is_queued_for_deletion():
			slots.append(child)
	
	# Désélectionner tous les slots
	for slot in slots:
		slot.set_selected(false)
	
	# Sélectionner le nouveau slot si valide
	if index >= 0 and index < slots.size():
		slots[index].set_selected(true)
