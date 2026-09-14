extends Node2D

@export var floor_y: float = 500.0
@export var player_start_x: float = 200.0
@export var dummy_start_x: float = 600.0

var camera: Camera2D
var player: CharacterBody2D
var dummy: CharacterBody2D

const FIGHTER_SCENE := preload("res://scenes/fighter_2d.tscn")

func _ready() -> void:
	setup_background()
	setup_floor()
	setup_camera()
	spawn_fighters()

func _process(delta: float) -> void:
	update_camera(delta)

func setup_background() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.08, 0.08, 0.12, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func setup_floor() -> void:
	var floor_body := StaticBody2D.new()
	floor_body.name = "Floor"
	add_child(floor_body)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000.0, 40.0)
	shape.shape = rect
	shape.position = Vector2(0.0, floor_y + 20.0)
	floor_body.add_child(shape)

	var visual := ColorRect.new()
	visual.name = "FloorVisual"
	visual.color = Color(0.18, 0.18, 0.22, 1)
	visual.size = Vector2(4000.0, 40.0)
	visual.position = Vector2(-2000.0, floor_y)
	add_child(visual)

func setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()

func spawn_fighters() -> void:
	player = FIGHTER_SCENE.instantiate() as CharacterBody2D
	player.name = "Player"
	player.position = Vector2(player_start_x, floor_y)
	add_child(player)

	dummy = FIGHTER_SCENE.instantiate() as CharacterBody2D
	dummy.name = "Dummy"
	dummy.position = Vector2(dummy_start_x, floor_y)
	add_child(dummy)

	player.opponent = dummy
	dummy.opponent = player

func update_camera(delta: float) -> void:
	if not player or not dummy or not camera:
		return

	var midpoint := (player.global_position + dummy.global_position) * 0.5
	midpoint.y = floor_y - 120.0
	camera.global_position = midpoint

	var separation := absf(player.global_position.x - dummy.global_position.x)
	var target_zoom := clampf(500.0 / maxf(separation, 200.0), 0.65, 1.25)
	camera.zoom = camera.zoom.lerp(Vector2(target_zoom, target_zoom), delta * 4.0)
