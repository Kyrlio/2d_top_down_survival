extends Control

var previous_position: Vector2
var angular_velocity: float = 0.0
var target_rotation: float = 0.0

# Configuration
const ROTATION_STRENGTH: float = 0.001 # Sensitivity of rotation to movement
const MAX_ROTATION: float = 0.7 # Max rotation in radians (approx 17 degrees)
const RECOVERY_SPEED: float = 10.0 # How fast it centers back
const SPRING_STIFFNESS: float = 200.0 # For the oscillation effect
const SPRING_DAMPING: float = 10.0

func _ready() -> void:
	# Initial Setup
	previous_position = global_position
	
	# "Lift" animation (POP effect)
	scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _process(delta: float) -> void:
	if delta == 0:
		return
		
	var current_position = global_position
	var velocity = (current_position - previous_position) / delta
	
	# Calculate target rotation based on horizontal velocity
	# Negative velocity.x (moving left) -> Rotate right (positive)
	# Positive velocity.x (moving right) -> Rotate left (negative)
	# This creates a "drag" effect.
	var lean =  velocity.x * ROTATION_STRENGTH
	lean = clamp(lean, -MAX_ROTATION, MAX_ROTATION)
	
	# Apply simple lerp for smoothness
	rotation = lerp_angle(rotation, lean, delta * RECOVERY_SPEED)
	
	previous_position = current_position
