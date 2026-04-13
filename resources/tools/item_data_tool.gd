class_name ItemDataTool extends ItemData

@export var tool_scene: PackedScene
@export var base_damage: int = 10
@export var attack_speed: float = 1.0
@export var range_multiplier: float = 1.0

# Runtime-only visual variant used by tool scenes (ex: sword skin/frame).
var runtime_skin_frame: int = -1

#var current_level: int = 1

## Use the tool 
## Target is the player or other entitie that can use a tool
func use(target) -> void:
	target.equip_tool(self)
	print("Base damage : ", base_damage)
	print("Attack speed : ", attack_speed)
	print("Range Multiplier : ", range_multiplier)
