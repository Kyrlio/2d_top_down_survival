extends PanelContainer

signal slot_clicked(index: int, button: int)

const TOOLTIP_SCENE = preload("res://components/inventory_component/item_tooltip.tscn")

var current_item_data: ItemData

@onready var texture_rect: TextureRect = $MarginContainer/TextureRect
@onready var quantity_label: Label = $QuantityLabel



func set_slot_data(slot_data: SlotData) -> void:
	var item_data = slot_data.item_data
	current_item_data = item_data
	texture_rect.texture = item_data.texture
	tooltip_text = " " # Active the tooltip but we use our custom one
	
	if slot_data.quantity > 1:
		quantity_label.text = "x%s" % slot_data.quantity
		quantity_label.show()
	else:
		quantity_label.hide()


func _make_custom_tooltip(for_text: String) -> Object:
	if current_item_data == null:
		return null
	var tooltip = TOOLTIP_SCENE.instantiate()
	tooltip.set_tooltip_data(current_item_data)
	return tooltip


func animate_pop() -> void:
	texture_rect.scale = Vector2(1.2, 1.2)
	var tween = create_tween()
	tween.tween_property(texture_rect, "scale", Vector2(0.9, 0.9), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(texture_rect, "scale", Vector2(1.0, 1.0), 0.1)


func set_selected(is_selected: bool) -> void:
	if is_selected:
		modulate = Color(1.2, 1.2, 0.8)  # Teinte jaune/dorée pour indiquer la sélection
	else:
		modulate = Color.WHITE


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT) and event.is_pressed():
		slot_clicked.emit(get_index(), event.button_index)
