extends Node2D

# ─────────────────────────────────────────────────────────────
# Constantes y tipos
# ─────────────────────────────────────────────────────────────
const CELL: int = 16
const W: int = 64
const H: int = 40

enum TileId {AIR, DIRT, STONE, FARMLAND, SPROUT, FLOWER}

# ─────────────────────────────────────────────────────────────
# Ajustes
# ─────────────────────────────────────────────────────────────
@export_range(0.0, 1.0, 0.05) var stone_chance: float = 1.0 / 7.0
@export_range(0.0, 1.0, 0.05) var growth_chance_per_day: float = 1.0 # 1.0 = siempre crece

# ─────────────────────────────────────────────────────────────

@onready var inventory = get_node("/root/Game/Inventory")
# Ciclo de día/noche y estaciones
var day_length := 600.0 # 10 minutos en segundos
var current_time := 0.0
var current_day := 1
var current_season := "primavera" # primavera, verano, otoño, invierno
var seasons := ["primavera", "verano", "otoño", "invierno"]
var season_days := 5 # días por estación

signal day_changed(current_day)
signal season_changed(current_season)
signal time_updated(current_time)


func _ready() -> void:
	set_process(true)
	rng.randomize()
	_generate_textures()
	_init_world_arrays()
	_generate_world()
	_draw_world()
	# Inicializa el inventario (ajusta la ruta si es necesario)
	#inventory = get_node_or_null("/root/Inventory")
	# Conecta la señal 'collected' de todos los recolectables
	for collectable in get_tree().get_nodes_in_group("collectables"):
		collectable.connect("collected", Callable(self, "_on_collectable_collected"))
	# Asigna el nodo del jugador (ajusta la ruta si es necesario)
	player = get_node_or_null("/root/Game/Player")
# Espíritu
# ─────────────────────────────────────────────────────────────
func _on_collectable_collected(resource_type: String, amount: int) -> void:
	if inventory:
		inventory.add_item(resource_type, amount)
		if resource_type == "flor_ananuca":
			inventory.add_item("semilla_ananuca", 3)

func _process(delta):
		current_time += delta
		if current_time >= day_length:
			current_time = 0
			current_day += 1
			_update_season()
			emit_signal("day_changed", current_day)
		# Actualiza la hora cada frame
		emit_signal("time_updated", current_time)

		# Movimiento del espíritu hacia el jugador
		if spirit_sprite and player:
			var target_pos = player.global_position
			var speed = 60.0 # píxeles por segundo
			var direction = (target_pos - spirit_sprite.position)
			if direction.length() > 2.0:
				direction = direction.normalized()
				spirit_sprite.position += direction * speed * delta

func _update_season():
	var season_index = int((current_day - 1) / season_days) % seasons.size()
	var new_season = seasons[season_index]
	if new_season != current_season:
		current_season = new_season
		emit_signal("season_changed", current_season)
	# Aquí puedes cambiar la apariencia del mundo según la estación
# ─────────────────────────────────────────────────────────────
var grid: Array = [] # 2D: Array[Array[int]]
var sprites: Array = [] # 2D: Array[Array[Sprite2D]]
var tex_by_id: Dictionary = {} # TileId -> Texture2D (o null)
var rng := RandomNumberGenerator.new()

var spirit_node: Node2D = null
var spirit_pos := Vector2.ZERO
var spirit_sprite: Sprite2D = null
var player: Node2D = null

# ─────────────────────────────────────────────────────────────
# Ciclo de vida
# ─────────────────────────────────────────────────────────────
# func _ready() -> void:
# 	rng.randomize()
# 	_generate_textures()
# 	_init_world_arrays()
# 	_generate_world()
# 	_draw_world()

# ─────────────────────────────────────────────────────────────
# Texturas
# ─────────────────────────────────────────────────────────────
func _generate_textures() -> void:
	tex_by_id[TileId.AIR] = null
	tex_by_id[TileId.DIRT] = _make_color_tex(Color(0.55, 0.35, 0.25))
	tex_by_id[TileId.STONE] = _make_color_tex(Color(0.45, 0.45, 0.50))
	tex_by_id[TileId.FARMLAND] = _make_color_tex(Color(0.45, 0.28, 0.18))
	tex_by_id[TileId.SPROUT] = load("res://assets/other/sc_grow_plant_001_1.png")
	tex_by_id[TileId.FLOWER] = load("res://assets/other/sc_grow_plant_001_2.png")

func _make_color_tex(c: Color) -> Texture2D:
	var img: Image = Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	img.fill(c)
	# Borde inferior sutil
	for x in CELL:
		img.set_pixel(x, CELL - 1, Color(0, 0, 0, 0.20))
	return ImageTexture.create_from_image(img)

# ─────────────────────────────────────────────────────────────
# Mundo
# ─────────────────────────────────────────────────────────────
func _init_world_arrays() -> void:
	grid.resize(H)
	sprites.resize(H)
	for y in H:
		grid[y] = []
		grid[y].resize(W)
		sprites[y] = []
		sprites[y].resize(W)
		for x in W:
			sprites[y][x] = null

func _generate_world() -> void:
	var ground_y: int = int(H / 2) + 4
	for y in H:
		for x in W:
			var v: int = TileId.AIR
			if y > ground_y:
				v = TileId.STONE if rng.randf() < stone_chance else TileId.DIRT
			elif y == ground_y:
				v = TileId.DIRT
			grid[y][x] = v

func _draw_world() -> void:
	for y in H:
		for x in W:
			_update_cell_visual(Vector2i(x, y))

# ─────────────────────────────────────────────────────────────
# Conversión / Utilidades
# ─────────────────────────────────────────────────────────────
func get_spawn_position() -> Vector2:
	return Vector2(W * CELL * 0.5, H * CELL * 0.5 - 64)

func cell_to_pos(c: Vector2i) -> Vector2:
	return Vector2(c.x * CELL + CELL * 0.5, c.y * CELL + CELL * 0.5)

func world_to_cell(p: Vector2) -> Vector2i:
	var x: int = int(floor(p.x / CELL))
	var y: int = int(floor(p.y / CELL))
	return Vector2i(clamp(x, 0, W - 1), clamp(y, 0, H - 1))

func _in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < W and c.y >= 0 and c.y < H

# ─────────────────────────────────────────────────────────────
# Render de celda (con pool de Sprite2D)
# ─────────────────────────────────────────────────────────────
func _ensure_sprite(c: Vector2i) -> Sprite2D:
	var s: Sprite2D = sprites[c.y][c.x]
	if s:
		return s
	s = Sprite2D.new()
	add_child(s)
	s.position = cell_to_pos(c)
	s.centered = true
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprites[c.y][c.x] = s
	# Si es sprout o flor, escala el sprite para que encaje en la celda
	var v: int = grid[c.y][c.x]
	if v == TileId.FLOWER or v == TileId.SPROUT:
		var tex: Texture2D = tex_by_id.get(v, null)
		if tex == null:
			print("No se encontró la textura para TileId ", v)
		else:
			s.scale = Vector2(CELL / float(tex.get_width()), CELL / float(tex.get_height()))
	return s

func _update_cell_visual(c: Vector2i) -> void:
	if not _in_bounds(c):
		return
	var v: int = grid[c.y][c.x]
	var s: Sprite2D = _ensure_sprite(c)
	var tex: Texture2D = tex_by_id.get(v, null)
	s.texture = tex

# ─────────────────────────────────────────────────────────────
# Interacciones
# ─────────────────────────────────────────────────────────────
func mine(c: Vector2i) -> String:
	if not _in_bounds(c):
		return ""
	var v: int = grid[c.y][c.x]
	match v:
		TileId.DIRT, TileId.FARMLAND:
			grid[c.y][c.x] = TileId.AIR
			_update_cell_visual(c)
			return "tierra"
		TileId.STONE:
			grid[c.y][c.x] = TileId.AIR
			_update_cell_visual(c)
			return "piedra"
		TileId.SPROUT:
			var item: String = "semilla_ananuca"
			grid[c.y][c.x] = TileId.FARMLAND
			_update_cell_visual(c)
			# if item != "" and inventory:
			# 	inventory.add_item(item, 1)
			return item
		TileId.FLOWER:
			grid[c.y][c.x] = TileId.AIR
			_update_cell_visual(c)
			# if inventory:
			# 	inventory.add_item("flor_ananuca", 1)
			if inventory:
				inventory.add_item("semilla_ananuca", 3)
			return "flor_ananuca"
		_:
			return ""

func place(c: Vector2i, what: String) -> bool:
	if not _in_bounds(c):
		return false
	if grid[c.y][c.x] != TileId.AIR:
		return false
	if what == "tierra":
		grid[c.y][c.x] = TileId.DIRT
		_update_cell_visual(c)
		return true
	return false

func till(c: Vector2i) -> void:
	if not _in_bounds(c):
		return
	if grid[c.y][c.x] == TileId.DIRT:
		grid[c.y][c.x] = TileId.FARMLAND
		_update_cell_visual(c)

func plant(c: Vector2i, plant_id: String) -> bool:
	if not _in_bounds(c):
		return false
	# soporta "ananuca" (en el futuro podrías mapear plant_id -> etapas)
	if grid[c.y][c.x] == TileId.FARMLAND and plant_id == "ananuca":
		grid[c.y][c.x] = TileId.SPROUT
		_update_cell_visual(c)
		return true
	return false

# ─────────────────────────────────────────────────────────────
# Simulación diaria
# ─────────────────────────────────────────────────────────────
func new_day() -> void:
	# Crecimiento simple: sprout -> flower con probabilidad
	for y in H:
		for x in W:
			if grid[y][x] == TileId.SPROUT and rng.randf() <= growth_chance_per_day:
				grid[y][x] = TileId.FLOWER
				_update_cell_visual(Vector2i(x, y))

func count_flowers() -> int:
	var n: int = 0
	for y in H:
		for x in W:
			if grid[y][x] == TileId.FLOWER:
				n += 1
	return n

# ─────────────────────────────────────────────────────────────
# Espíritu
# ─────────────────────────────────────────────────────────────
func spawn_spirit() -> void:
	if spirit_node:
		return
	spirit_node = Node2D.new()
	add_child(spirit_node)

	# Centro desplazado
	var c: Vector2i = Vector2i(W / 2 + 3, H / 2 + 1)
	spirit_pos = cell_to_pos(c)

	# Halo (ligero y barato)
	var halo: ColorRect = ColorRect.new()
	halo.color = Color(1, 0, 0, 0.15)
	halo.size = Vector2(CELL * 2, CELL * 2)
	halo.position = spirit_pos - halo.size * 0.5
	spirit_node.add_child(halo)

	# Sprite del espíritu
	spirit_sprite = Sprite2D.new()
	spirit_sprite.texture = load("res://assets/other/spirit.png") # Ajusta la ruta si es necesario
	spirit_sprite.position = spirit_pos
	spirit_sprite.centered = true
	spirit_node.add_child(spirit_sprite)

	var label: Label = Label.new()
	label.text = "Espíritu de Añañuca"
	label.position = spirit_pos + Vector2(-80, -32)
	spirit_node.add_child(label)

func despawn_spirit() -> void:
	if spirit_node and is_instance_valid(spirit_node):
		spirit_node.queue_free()
	spirit_node = null

func player_near_spirit(p: Vector2) -> bool:
	if not spirit_node:
		return false
	return p.distance_to(spirit_pos) < 60.0
