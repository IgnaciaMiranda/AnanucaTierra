extends Node2D

# Ciclo de crecimiento de la Añañuca
var state: String = "semilla" # semilla, brote, pequeña, adulta, florecida
var days_in_state: int = 0
var needs_water: bool = true

signal grew(new_state)

@onready var particles = $Particles2D


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

# Permite recolectar la planta adulta/florecida y dar 2 semillas al jugador
func collect(player):
	if state == "adulta" or state == "florecida":
		if player and player.has_method("add_seeds"):
			player.add_seeds(2)
		queue_free()
