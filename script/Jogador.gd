extends CharacterBody2D

signal health_changed(current_health: int)
signal died

enum State { IDLE, WALK, KNOCKBACK, DEAD }

const SPEED = 80.0
const KNOCKBACK_FORCE = 200.0
const INVINCIBILITY_TIME = 1.0
const MIN_KNOCKBACK = 10.0
const PLAYER_MARGIN = 8.0

@export var max_health := 5

var health := max_health
var invincible := false
var knockback := Vector2.ZERO
var state := State.IDLE
var map_bounds := Rect2()

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")
	health = max_health
	_setup_map_limits()
	_enter_state(State.IDLE)


func _setup_map_limits() -> void:
	var ground := get_parent().get_node_or_null("Chao") as TileMapLayer
	if ground == null:
		return
	var used := ground.get_used_rect()
	var half := Vector2(ground.tile_set.tile_size) / 2.0
	var top_left := ground.to_global(ground.map_to_local(used.position) - half)
	var bottom_right := ground.to_global(ground.map_to_local(used.end - Vector2i.ONE) + half)
	map_bounds = Rect2(top_left, bottom_right - top_left).grow(-PLAYER_MARGIN)

	var camera := $Camera2D as Camera2D
	camera.limit_left = int(top_left.x)
	camera.limit_top = int(top_left.y)
	camera.limit_right = int(bottom_right.x)
	camera.limit_bottom = int(bottom_right.y)


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")

	match state:
		State.IDLE:
			_state_idle(direction)
		State.WALK:
			_state_walk(direction)
		State.KNOCKBACK:
			_state_knockback(direction, delta)
		State.DEAD:
			return

	move_and_slide()
	if map_bounds.has_area():
		global_position = global_position.clamp(map_bounds.position, map_bounds.end)

func _state_idle(direction: Vector2) -> void:
	velocity = Vector2.ZERO
	if direction != Vector2.ZERO:
		change_state(State.WALK)


func _state_walk(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		change_state(State.IDLE)
		velocity = Vector2.ZERO
		return

	velocity = direction * SPEED
	_flip_sprite(direction)


func _state_knockback(direction: Vector2, delta: float) -> void:
	velocity = direction * SPEED + knockback
	knockback = knockback.move_toward(Vector2.ZERO, KNOCKBACK_FORCE * 4 * delta)
	_flip_sprite(direction)

	if knockback.length() <= MIN_KNOCKBACK:
		knockback = Vector2.ZERO
		change_state(State.WALK if direction != Vector2.ZERO else State.IDLE)


func change_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	_enter_state(new_state)


func _enter_state(new_state: State) -> void:
	match new_state:
		State.IDLE:
			sprite.play("idle")
		State.WALK:
			sprite.play("walk")
		State.KNOCKBACK:
			sprite.play("hurt")
		State.DEAD:
			velocity = Vector2.ZERO
			sprite.play("hurt")


func _flip_sprite(direction: Vector2) -> void:
	if direction.x != 0:
		sprite.flip_h = direction.x < 0


func take_damage(amount: int, source: Vector2) -> void:
	if invincible or state == State.DEAD:
		return

	health -= amount
	health_changed.emit(health)

	if health <= 0:
		die()
		return

	knockback = (global_position - source).normalized() * KNOCKBACK_FORCE
	change_state(State.KNOCKBACK)
	_become_invincible()


func _become_invincible() -> void:
	invincible = true
	var blink := create_tween().set_loops(int(INVINCIBILITY_TIME / 0.2))
	blink.tween_property(sprite, "modulate:a", 0.3, 0.1)
	blink.tween_property(sprite, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(INVINCIBILITY_TIME).timeout
	sprite.modulate.a = 1.0
	invincible = false


func die() -> void:
	change_state(State.DEAD)
	died.emit()
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
