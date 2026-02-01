class_name ItemDataTool extends ItemData

@export var tool_scene: PackedScene

## Use the tool 
## Target is the player or other entitie that can use a tool
func use(target) -> void:
	target.equip_tool(self)
