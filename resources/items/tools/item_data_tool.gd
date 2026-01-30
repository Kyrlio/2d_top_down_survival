class_name ItemDataTool extends ItemData

@export var tool_scene: PackedScene


func use(target) -> void:
	target.equip_tool(self)
 
