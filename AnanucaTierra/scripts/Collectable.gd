extends Area2D

# Base para objetos recolectables
@export var resource_type: String = "piedra"
@export var amount: int = 1

signal collected(resource_type, amount)

func collect():
	emit_signal("collected", resource_type, amount)
	queue_free()
