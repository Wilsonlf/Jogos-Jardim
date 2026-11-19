extends CanvasLayer

@export var survival_time := 180.0

var time_left := 0.0
var finished := false

var time_label: Label
var health_label: Label
var message_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	time_left = survival_time
	_build_ui()

	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.health_changed.connect(_update_health)
		player.died.connect(_on_player_died)
		_update_health(player.health)
	_update_time()


func _process(delta: float) -> void:
	if finished:
		return
	time_left = maxf(time_left - delta, 0.0)
	_update_time()
	if time_left <= 0.0:
		_win()


func _build_ui() -> void:
	time_label = _make_label(Control.PRESET_CENTER_TOP, 40)
	health_label = _make_label(Control.PRESET_TOP_LEFT, 28)
	health_label.grow_horizontal = Control.GROW_DIRECTION_END
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	health_label.offset_left = 16
	health_label.offset_top = 12
	health_label.text = "Vida: 0"

	message_label = _make_label(Control.PRESET_CENTER, 64)
	message_label.visible = false

## Usei IA para criação dos HUDs fixo na tela
func _make_label(preset: int, size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	label.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	return label


func _update_time() -> void:
	var total := int(ceil(time_left))
	time_label.text = "%d:%02d" % [total / 60, total % 60]


func _update_health(current: int) -> void:
	health_label.text = "Vida: %d" % maxi(current, 0)


func _on_player_died() -> void:
	finished = true
	_show_message("Você morreu!")


func _win() -> void:
	finished = true
	_show_message("Você sobreviveu!")
	get_tree().paused = true
	await get_tree().create_timer(3.0).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()


func _show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	message_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	message_label.grow_vertical = Control.GROW_DIRECTION_BOTH
