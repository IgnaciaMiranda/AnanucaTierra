extends Area2D

# Base para objetos recolectables
export(String) var resource_type = "piedra"
export(int) var amount = 1

signal collected(resource_type, amount)

func collect():
	emit_signal("collected", resource_type, amount)
	queue_free()
