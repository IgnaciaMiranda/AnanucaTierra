extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
# Constantes y tipos
# ─────────────────────────────────────────────────────────────────────────────
enum Slot {PICKAXE = 1, DIRT = 2, HOE = 3, SEEDS = 4}
enum Quest {START, NIGHT_SPIRIT, COMPLETE}

const ITEM_DIRT := "tierra"
const ITEM_SEED_ANANUCA := "semilla_ananuca"
const ITEM_FLOWER_ANANUCA := "flor_ananuca"
const ITEM_STONE := "piedra"

const DAWN_START := 5.5
const DAY_FULL := 7.0
const DUSK_START := 18.0
const NIGHT_START := 20.0
const NIGHT_BRIGHTNESS := 0.5
const DAY_BRIGHTNESS := 1.0

# ─────────────────────────────────────────────────────────────────────────────
# Tuning desde el editor
# ─────────────────────────────────────────────────────────────────────────────
@export var time_of_day: float = 6.0 # 0..24
@export var time_scale_hours_per_sec: float = 0.25 # horas que avanzan por segundo real
@export var required_flowers: int = 5

# ─────────────────────────────────────────────────────────────────────────────
# Nodos
# ─────────────────────────────────────────────────────────────────────────────
@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var info_label: Label = $HUD/Info
@onready var quest_label: Label = $HUD/Quest

# ─────────────────────────────────────────────────────────────────────────────
# Estado
# ─────────────────────────────────────────────────────────────────────────────
var world: Node
var player: Node

# Usar el nodo Inventory como inventario principal
@onready var inventory_node = get_node("./Inventory")
var selected_slot: int = Slot.PICKAXE
var quest_state: int = Quest.START

# ─────────────────────────────────────────────────────────────────────────────
# Ciclo de vida
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Crea mundo y jugador
	world = load("res://scenes/World.tscn").instantiate()
	add_child(world)
	player = load("res://scenes/Player.tscn").instantiate()
	add_child(player)
	
	# FIXED: Separar la verificación de la asignación
	if "get_spawn_position" in world:
		var spawn_pos: Vector2 = world.get_spawn_position()
		player.global_position = spawn_pos

	# FIXED: También separar esta verificación
	if inventory_node == null:
		push_warning("Inventory node not found! Some features may not work.")
	else:
		if "inventory_ref" in player:
			player.inventory_ref = inventory_node.items

	# Conectar señales de World al HUD
	var hud = $HUD
	world.connect("day_changed", Callable(hud, "update_day"))
	world.connect("season_changed", Callable(hud, "update_season"))
	world.connect("time_updated", Callable(hud, "update_time"))
	_update_hud()
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	# Avanza el tiempo independientemente del framerate
	var prev_time: float = time_of_day
	time_of_day = wrapf(time_of_day + time_scale_hours_per_sec * delta, 0.0, 24.0)

	# Detecta amanecer real (cruce 24->0) para nuevo día
	if prev_time > time_of_day:
		if "new_day" in world:
			world.new_day() # cultivos crecen al amanecer

	# Iluminación simple día/noche
	_update_day_night_modulate()

	# Progreso de misión y HUD
	_update_quest()
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("slot_1"):
		selected_slot = Slot.PICKAXE
	elif event.is_action_pressed("slot_2"):
		selected_slot = Slot.DIRT
	elif event.is_action_pressed("slot_3"):
		selected_slot = Slot.HOE
	elif event.is_action_pressed("slot_4"):
		selected_slot = Slot.SEEDS

	if event.is_action_pressed("action_mine"):
		_on_use_tool(get_global_mouse_position(), true)
	elif event.is_action_pressed("action_place"):
		_on_use_tool(get_global_mouse_position(), false)

# ─────────────────────────────────────────────────────────────────────────────
# Lógica de herramientas
# ─────────────────────────────────────────────────────────────────────────────
func _on_use_tool(pos: Vector2, primary: bool) -> void:
	if world == null or !"world_to_cell" in world:
		return

	var cell: Vector2i = world.world_to_cell(pos)

	match selected_slot:
		Slot.PICKAXE:
			if !"mine" in world:
				return
			var got: String = world.mine(cell)
			if got != "":
				inventory_node.add_item(got, 1)

		Slot.DIRT:
			if !"place" in world:
				return
			if inventory_node.get_count(ITEM_DIRT) > 0 and world.place(cell, ITEM_DIRT):
				inventory_node.remove_item(ITEM_DIRT, 1)

		Slot.HOE:
			if "till" in world:
				world.till(cell)

		Slot.SEEDS:
			if !"plant" in world:
				return
			if inventory_node.get_count(ITEM_SEED_ANANUCA) > 0 and world.plant(cell, "ananuca"):
				inventory_node.remove_item(ITEM_SEED_ANANUCA, 1)

# ─────────────────────────────────────────────────────────────────────────────
# UI / HUD
# ─────────────────────────────────────────────────────────────────────────────
func _update_hud() -> void:
	info_label.text = "Hora: %.2f  |  [1] Pico  [2] Tierra(%d)  [3] Azadón  [4] Semillas(%d)  |  Añañucas(%d)" % [
		time_of_day,
		inventory_node.get_count(ITEM_DIRT),
		inventory_node.get_count(ITEM_SEED_ANANUCA),
		inventory_node.get_count(ITEM_FLOWER_ANANUCA)
	]
	quest_label.text = _quest_text()

func _quest_text() -> String:
	match quest_state:
		Quest.START:
			return "Leyenda: Añañuca.\nAyuda a que florezcan las Añañucas en el Valle del Limarí.\nPlanta %d para invocar al Espíritu de Añañuca al anochecer." % required_flowers
		Quest.NIGHT_SPIRIT:
			return "La noche cae en el Valle... Busca el brillo rojo de Añañuca.\nLleva %d flores al espíritu." % required_flowers
		Quest.COMPLETE:
			return "¡Gracias! Añañuca vuelve a florecer cada primavera.\n(Termina la demo)"
		_:
			return ""

# ─────────────────────────────────────────────────────────────────────────────
# Misión
# ─────────────────────────────────────────────────────────────────────────────
func _update_quest() -> void:
	match quest_state:
		Quest.START:
			if time_of_day >= NIGHT_START and _count_flowers_in_world() >= required_flowers:
				quest_state = Quest.NIGHT_SPIRIT
				if "spawn_spirit" in world:
					world.spawn_spirit()
		Quest.NIGHT_SPIRIT:
			if "player_near_spirit" in world and world.player_near_spirit(player.global_position):
				var have: int = inventory_node.get_count(ITEM_FLOWER_ANANUCA)
				if have >= required_flowers:
					inventory_node.remove_item(ITEM_FLOWER_ANANUCA, required_flowers)
					quest_state = Quest.COMPLETE

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────
func _update_day_night_modulate() -> void:
	var b: float = _brightness_for_time(time_of_day)
	canvas_modulate.color = Color(b, b, b, 1.0)

func _brightness_for_time(t: float) -> float:
	# Noche
	if t < DAWN_START or t > NIGHT_START:
		return NIGHT_BRIGHTNESS
	# Amanecer: va de 0.5 -> 1.0 entre [5.5, 7.0]
	if t < DAY_FULL:
		return lerp(NIGHT_BRIGHTNESS, DAY_BRIGHTNESS, (t - DAWN_START) / (DAY_FULL - DAWN_START))
	# Atardecer: va de 1.0 -> 0.5 entre [18.0, 20.0]
	if t > DUSK_START:
		return lerp(DAY_BRIGHTNESS, NIGHT_BRIGHTNESS, (t - DUSK_START) / (NIGHT_START - DUSK_START))
	# Día
	return DAY_BRIGHTNESS

func _count_flowers_in_world() -> int:
	if "count_flowers" in world:
		return int(world.count_flowers())
	return 0
