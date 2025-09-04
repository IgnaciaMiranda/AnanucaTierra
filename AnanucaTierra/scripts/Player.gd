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
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_init_texture()
	_init_collision()

func _physics_process(delta: float) -> void:
	# Entrada unificada: WASD personalizado
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var desired_vel: Vector2 = input_dir * max_speed

	# Acelera hacia desired_vel; si no hay input, aplica fricción hacia 0
	var rate: float = accel if input_dir != Vector2.ZERO else friction
	velocity = velocity.move_toward(desired_vel, rate * delta)

	move_and_slide()

	# Giro horizontal sencillo
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0


func _process(delta):
	_update_animation()

func _update_animation():
	if is_on_floor():
		if velocity.x == 0:
			anim_sprite.play("idle")
		elif abs(velocity.x) > 200:
			anim_sprite.play("run")
		else:
			anim_sprite.play("walk")
	else:
		if velocity.y < 0:
			anim_sprite.play("jump")
		elif velocity.y > 0:
			anim_sprite.play("fall")

# Ejemplo para daño y muerte (debes llamar estas funciones cuando corresponda)
func play_hurt():
	anim_sprite.play("hurt")

func play_death():
	anim_sprite.play("death")

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _init_texture() -> void:
	var w: int = max(1, sprite_size.x)
	var h: int = max(1, sprite_size.y)


	sprite.centered = true
	# Mantener pixel-art nítido (Godot 4)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _init_collision() -> void:
	var rect: RectangleShape2D = RectangleShape2D.new()
	# La colisión igual al sprite
	rect.size = Vector2(sprite_size)
	col.shape = rect
