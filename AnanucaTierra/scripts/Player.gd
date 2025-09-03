extends CharacterBody2D
## Player simple con movimiento 2D suave y sprite generado.

# ─────────────────────────────────────────────────────────────
# Tuning desde el editor
# ─────────────────────────────────────────────────────────────
@export_range(60.0, 600.0, 10.0) var max_speed: float = 180.0
@export_range(200.0, 4000.0, 50.0) var accel: float = 1200.0
@export_range(200.0, 6000.0, 50.0) var friction: float = 1800.0
@export var sprite_size: Vector2i = Vector2i(16, 16)
@export var border_thickness: int = 1
@export var body_color: Color = Color(0.1, 0.2, 0.7, 1.0)
@export var border_color: Color = Color(1, 1, 1, 1)

# Referencia a inventario (inyectada desde fuera)
var inventory_ref: Dictionary = {}

# ─────────────────────────────────────────────────────────────
# Nodos
# ─────────────────────────────────────────────────────────────
@onready var sprite: Sprite2D = $Sprite
@onready var col: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_init_texture()
	_init_collision()

func _physics_process(delta: float) -> void:
	# Entrada unificada: (izq, der, arr, aba)
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var desired_vel: Vector2 = input_dir * max_speed

	# Acelera hacia desired_vel; si no hay input, aplica fricción hacia 0
	var rate := accel if input_dir != Vector2.ZERO else friction
	velocity = velocity.move_toward(desired_vel, rate * delta)

	move_and_slide()

	# Giro horizontal sencillo
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _init_texture() -> void:
	var w := max(1, sprite_size.x)
	var h := max(1, sprite_size.y)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(body_color)

	# Borde
	for x in w:
		for y in h:
			var on_border := x < border_thickness \
				or y < border_thickness \
				or x >= w - border_thickness \
				or y >= h - border_thickness
			if on_border:
				img.set_pixel(x, y, border_color)

	var tex := ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.centered = true
	# Mantener pixel-art nítido (Godot 4)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _init_collision() -> void:
	var rect := RectangleShape2D.new()
	# La colisión igual al sprite
	rect.size = Vector2(sprite_size)
	col.shape = rect
