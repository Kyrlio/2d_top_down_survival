class_name ItemSlot extends Panel

@export var item: ItemData

@onready var icon: TextureRect = $Icon

var slot_index: int = -1

func _ready() -> void:
	update_ui()


func update_ui() -> void:
	if not item:
		icon.texture = null
		return
	
	icon.texture = item.icon
	tooltip_text = item.name


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not item:
		return
	
	var preview = duplicate()
	var c = Control.new()
	c.set_script(load("uid://r42xm8am7dyb"))
	c.add_child(preview)
	preview.position -= Vector2(0, 0)
	preview.self_modulate = Color.TRANSPARENT
	#c.modulate = Color(c.modulate, 0.95)
	
	set_drag_preview(c)
	icon.hide()
	
	return self


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		print("hiu")
	return data is Control and "item" in data


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var my_pos = icon.global_position
	var other_pos = data.icon.global_position
	
	var has_target_item = item != null
	var tmp = item
	item = data.item
	data.item = tmp
	
	icon.show()
	data.icon.show()
	
	update_ui()
	data.update_ui()
	
	if has_target_item:
		_animate_move(icon, other_pos, my_pos)
		_animate_move(data.icon, my_pos, other_pos)
	else:
		_animate_pop()


func _animate_pop() -> void:
	icon.scale = Vector2(1.2, 1.2)
	var tween = create_tween()
	tween.tween_property(icon, "scale", Vector2(0.9, 0.9), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.1)


func _animate_move(target: Control, from: Vector2, to: Vector2) -> void:
	target.global_position = from
	target.z_index = 10
	var tween = create_tween()
	tween.tween_property(target, "global_position", to, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): target.z_index = 0)
