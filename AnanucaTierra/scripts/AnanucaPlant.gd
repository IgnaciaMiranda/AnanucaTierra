extends Node2D

# Ciclo de crecimiento de la Añañuca
var state := "semilla" # semilla, brote, pequeña, adulta, florecida
var days_in_state := 0
var needs_water := true

signal grew(new_state)

onready var particles = $Particles2D setget _set_particles

func _set_particles(value):
	particles = value

func _process(delta):
	if state == "florecida" and _is_night():
		if particles:
			particles.emitting = true
	else:
		if particles:
			particles.emitting = false

func _is_night():
	var world = get_node_or_null("../World")
	if world:
		return world.current_time > world.day_length * 0.75
	return false

func _ready():
	set_process(true)

func _process(delta):
	# Aquí se puede conectar con el sistema de día/noche
	pass

func water():
	needs_water = false

func advance_growth():
	if state == "semilla":
		state = "brote"
	elif state == "brote":
		state = "pequeña"
	elif state == "pequeña":
		state = "adulta"
	elif state == "adulta":
		state = "florecida"
	emit_signal("grew", state)
	needs_water = true
