extends CharacterBody2D

enum State { IDLE, CHASE }

@export var damage := 1
@export var speed := 50.0
@export var detection_radius := 150.0
@export var lose_radius := 200.0

var state := State.IDLE
var player: Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	_enter_state(State.IDLE)


func _physics_process(_delta: float) -> void:
	match state:
		State.IDLE:
			_state_idle()
		State.CHASE:
			_state_chase()

	move_and_slide()
	_hit_player()


func _state_idle() -> void:
	velocity = Vector2.ZERO
	if _distance_to_player() <= detection_radius:
		change_state(State.CHASE)


func _state_chase() -> void:
	if _distance_to_player() > lose_radius:
		change_state(State.IDLE)
		velocity = Vector2.ZERO
		return

	var direction := global_position.direction_to(player.global_position)
	velocity = direction * speed
	if direction.x != 0:
		sprite.flip_h = direction.x < 0


func change_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	_enter_state(new_state)


func _enter_state(new_state: State) -> void:
	match new_state:
		State.IDLE:
			sprite.play("Waddling")
		State.CHASE:
			sprite.play("fly")


func _distance_to_player() -> float:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return INF
	return global_position.distance_to(player.global_position)


func _hit_player() -> void:
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, global_position)
