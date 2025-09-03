extends Node2D

# ─────────────────────────────────────────────────────────────
# Constantes y tipos
# ─────────────────────────────────────────────────────────────
const CELL: int = 16
const W: int = 64
const H: int = 40

enum TileId { AIR, DIRT, STONE, FARMLAND, SPROUT, FLOWER }

# ─────────────────────────────────────────────────────────────
# Ajustes
# ─────────────────────────────────────────────────────────────
@export_range(0.0, 1.0, 0.05) var stone_chance: float = 1.0 / 7.0
@export_range(0.0, 1.0, 0.05) var growth_chance_per_day: float = 1.0  # 1.0 = siempre crece

# ─────────────────────────────────────────────────────────────
# Estado
# ─────────────────────────────────────────────────────────────
var grid: Array = []                     # 2D: Array[Array[int]]
var sprites: Array = []                  # 2D: Array[Array[Sprite2D]]
var tex_by_id: Dictionary = {}           # TileId -> Texture2D (o null)
var rng := RandomNumberGenerator.new()

var spirit_node: Node2D = null
var spirit_pos := Vector2.ZERO

# ─────────────────────────────────────────────────────────────
# Ciclo de vida
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	rng.randomize()
	_generate_textures()
	_init_world_arrays()
	_generate_world()
	_draw_world()

# ─────────────────────────────────────────────────────────────
# Texturas
# ─────────────────────────────────────────────────────────────
func _generate_textures() -> void:
	tex_by_id[TileId.AIR]      = null
	tex_by_id[TileId.DIRT]     = _make_color_tex(Color(0.55, 0.35, 0.25))
	tex_by_id[TileId.STONE]    = _make_color_tex(Color(0.45, 0.45, 0.50))
	tex_by_id[TileId.FARMLAND] = _make_color_tex(Color(0.45, 0.28, 0.18))
	tex_by_id[TileId.SPROUT]   = _make_color_tex(Color(0.20, 0.70, 0.20))
	tex_by_id[TileId.FLOWER]   = _make_color_tex(Color(0.90, 0.10, 0.20))

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
		TileId.SPROUT, TileId.FLOWER:
			var item: String = "flor_ananuca" if v == TileId.FLOWER else ""
			grid[c.y][c.x] = TileId.AIR
			_update_cell_visual(c)
			return item
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
	halo.color = Color(1, 0, 0, 0.25)
	halo.size = Vector2(CELL * 2, CELL * 2)
	halo.position = spirit_pos - halo.size * 0.5
	spirit_node.add_child(halo)

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
	return p.distance_to(spirit_pos) < 40.0