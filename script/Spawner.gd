extends Node2D

@export var carp_scene: PackedScene
@export var ground: TileMapLayer

@export var initial_interval := 4.0
@export var min_interval := 1.0
@export var interval_decrease := 0.1
@export var max_carps := 15

@export var spawn_distance := 280.0
@export var speed_increase := 1.0
@export var max_speed := 75.0

const SPAWN_ATTEMPTS := 10
const CHASE_RADIUS := 10000.0

var interval := initial_interval
var carp_speed := 0.0
var carps: Array = []

@onready var timer: Timer = $Timer


func _ready() -> void:
	interval = initial_interval
	var sample = carp_scene.instantiate()
	carp_speed = sample.speed
	sample.free()
	timer.timeout.connect(_on_timer_timeout)
	timer.start(interval)


func _on_timer_timeout() -> void:
	carps = carps.filter(func(carp): return is_instance_valid(carp))
	if carps.size() < max_carps:
		_spawn_carp()

	interval = maxf(interval - interval_decrease, min_interval)
	carp_speed = minf(carp_speed + speed_increase, max_speed)
	timer.start(interval)


func _spawn_carp() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var position_found = _find_spawn_position(player.global_position)
	if position_found == null:
		return

	var carp = carp_scene.instantiate()
	carp.speed = carp_speed
	carp.detection_radius = CHASE_RADIUS
	carp.lose_radius = CHASE_RADIUS
	get_parent().add_child(carp)
	carp.global_position = position_found
	carps.append(carp)


func _find_spawn_position(center: Vector2) -> Variant:
	for i in SPAWN_ATTEMPTS:
		var candidate := center + Vector2.RIGHT.rotated(randf() * TAU) * spawn_distance
		if _is_valid_position(candidate):
			return candidate
	return null


func _is_valid_position(pos: Vector2) -> bool:
	if ground != null:
		var cell := ground.local_to_map(ground.to_local(pos))
		if ground.get_cell_source_id(cell) == -1:
			return false

	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	return get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()
