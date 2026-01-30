extends Control

signal drop_slot_data(slot_data: SlotData)
signal force_close

var grabbed_slot_data: SlotData
var external_inventory_owner
var previous_mouse_position: Vector2

@onready var player_inventory: PanelContainer = $PlayerInventory
@onready var grabbed_slot: PanelContainer = $GrabbedSlot
@onready var external_inventory: PanelContainer = $ExternalInventory
@onready var equip_inventory: PanelContainer = $EquipInventory

const ROTATION_STRENGTH: float = 0.001
const MAX_ROTATION: float = 0.7
const RECOVERY_SPEED: float = 10.0

func _ready() -> void:
	grabbed_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in grabbed_slot.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	previous_mouse_position = get_global_mouse_position()


func _process(delta: float) -> void:
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position()
		
		# Animation de rotation pendant le drag
		if delta > 0:
			var current_mouse_position = get_global_mouse_position()
			var velocity = (current_mouse_position - previous_mouse_position) / delta
			
			var lean = velocity.x * ROTATION_STRENGTH
			lean = clamp(lean, -MAX_ROTATION, MAX_ROTATION)
			
			grabbed_slot.rotation = lerp_angle(grabbed_slot.rotation, lean, delta * RECOVERY_SPEED)
			
			previous_mouse_position = current_mouse_position
			
	if external_inventory_owner and external_inventory_owner.global_position.distance_to(PlayerManager.get_global_position()) > 25:
		force_close.emit()


func set_player_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)


func set_equip_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	equip_inventory.set_inventory_data(inventory_data)


func set_external_inventory(_external_inventory_owner) -> void:
	external_inventory_owner = _external_inventory_owner
	var inventory_data = external_inventory_owner.inventory_data
	
	inventory_data.inventory_interact.connect(on_inventory_interact)
	external_inventory.set_inventory_data(inventory_data)
	
	external_inventory.show()


func clear_external_inventory() -> void:
	if external_inventory_owner:
		var inventory_data = external_inventory_owner.inventory_data
		
		inventory_data.inventory_interact.disconnect(on_inventory_interact)
		external_inventory.clear_inventory_data(inventory_data)
		
		external_inventory.hide()
		external_inventory_owner = null


func on_inventory_interact(inventory_data: InventoryData, index: int, button: int) -> void:
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
		[null, MOUSE_BUTTON_RIGHT]:
			inventory_data.use_slot_data(index)
		[_, MOUSE_BUTTON_RIGHT]:
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)
	
	update_grabbed_slot()


func update_grabbed_slot() -> void:
	if grabbed_slot_data:
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grabbed_slot_data)
		# Animation "lift" quand on grab
		grabbed_slot.scale = Vector2(0.1, 0.1)
		grabbed_slot.rotation = 0
		var tween = create_tween()
		tween.tween_property(grabbed_slot, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(grabbed_slot, "scale", Vector2(1, 1), 0.1)
		previous_mouse_position = get_global_mouse_position()
	else:
		grabbed_slot.hide()
		grabbed_slot.rotation = 0


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and grabbed_slot_data:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				drop_slot_data.emit(grabbed_slot_data)
				grabbed_slot_data = null
			MOUSE_BUTTON_RIGHT:
				drop_slot_data.emit(grabbed_slot_data.create_single_slot_data())
				if grabbed_slot_data.quantity < 1:
					grabbed_slot_data = null
		
		update_grabbed_slot()


func _on_visibility_changed() -> void:
	# if closing inventory and holding something
	if not visible and grabbed_slot_data:
		drop_slot_data.emit(grabbed_slot_data)
		grabbed_slot_data = null
		update_grabbed_slot()
