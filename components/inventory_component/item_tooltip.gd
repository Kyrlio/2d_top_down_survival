extends PanelContainer

@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var h_separator_2: HSeparator = %HSeparator2
@onready var stats_container: VBoxContainer = %StatsContainer
@onready var damage_label: Label = %DamageLabel
@onready var speed_label: Label = %SpeedLabel
@onready var range_label: Label = %RangeLabel

var current_item_data: ItemData

func set_tooltip_data(item_data: ItemData) -> void:
	current_item_data = item_data

func _ready() -> void:
	if current_item_data == null:
		return
		
	name_label.text = current_item_data.name
	desc_label.text = current_item_data.description
	
	if current_item_data is ItemDataTool:
		h_separator_2.show()
		stats_container.show()
		damage_label.text = "Damage : " + str(current_item_data.base_damage)
		speed_label.text = "Speed : " + str(current_item_data.attack_speed)
		range_label.text = "Size : " + str(current_item_data.range_multiplier)
	elif current_item_data is ItemDataConsumable:
		h_separator_2.show()
		stats_container.show()
		speed_label.hide()
		range_label.hide()
		damage_label.text = "Heal " + str(current_item_data.heal_value) + " PV"
	else:
		h_separator_2.hide()
		stats_container.hide()
