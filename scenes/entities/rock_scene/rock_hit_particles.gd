extends Node2D

@onready var gpu_particles: GPUParticles2D = $GPUParticles2D


func spawn_hit_particles() -> void:
	gpu_particles.emitting = true
