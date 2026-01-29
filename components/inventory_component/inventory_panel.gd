extends Panel


var data_bk
func _notification(what: int) -> void:
	if what == Node.NOTIFICATION_DRAG_BEGIN:
		data_bk = get_viewport().gui_get_drag_data()
	if what == Node.NOTIFICATION_DRAG_END:
			if not is_drag_successful():
				if data_bk:
					data_bk.icon.show()
					data_bk = null
