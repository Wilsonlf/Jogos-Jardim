extends CharacterBody2D

@export var dano := 1

@onready var hitbox: Area2D = $Hitbox


func _physics_process(_delta: float) -> void:
	for corpo in hitbox.get_overlapping_bodies():
		if corpo.is_in_group("player") and corpo.has_method("take_damage"):
			corpo.take_damage(dano, global_position)
