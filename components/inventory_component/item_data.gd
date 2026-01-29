class_name ItemData extends Resource


@export var name: String = ""
@export_multiline() var description: String = ""
@export var icon: Texture2D
@export var stackable: bool = false
@export_enum("ARME", "ARMURE", "MATERIAU", "CONSOMMABLE") var item_type: int
@export var stats: Dictionary = {}
