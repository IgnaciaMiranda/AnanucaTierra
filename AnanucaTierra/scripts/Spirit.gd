extends Node2D

# Espíritu de Añañuca
var active := false

signal spirit_appeared
signal flowers_delivered(count)

func appear():
	active = true
	emit_signal("spirit_appeared")
	# Aquí puedes activar animaciones y efectos visuales

func deliver_flowers(count):
	emit_signal("flowers_delivered", count)
	# Aquí puedes mostrar mensaje o cinemática
