extends Control

var grabbed_slot_data: SlotData
var external_inventory_owner
var previous_mouse_position: Vector2

@onready var player_inventory: PanelContainer = $PlayerInventory
@onready var grabbed_slot: PanelContainer = $GrabbedSlot
@onready var external_inventory: PanelContainer = $ExternalInventory

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


func set_player_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)


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
			pass
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
		tween.tween_property(grabbed_slot, "scale", Vector2(0.75, 0.75), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(grabbed_slot, "scale", Vector2(0.65, 0.65), 0.1)
		previous_mouse_position = get_global_mouse_position()
	else:
		grabbed_slot.hide()
		grabbed_slot.rotation = 0
