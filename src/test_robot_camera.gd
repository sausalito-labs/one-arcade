extends Camera2D

@export var target_path: NodePath = ^"../SkeletalPlayer"
@export var follow_offset: Vector2 = Vector2(0, -90)
@export var zoom_speed: float = 3.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 8.0

@onready var target: Node2D = get_node_or_null(target_path)

func _ready() -> void:
	if target:
		global_position = target.global_position + follow_offset

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_KP_ADD): # '+' key
		zoom += Vector2.ONE * zoom_speed * delta
	elif Input.is_key_pressed(KEY_MINUS) or Input.is_key_pressed(KEY_KP_SUBTRACT): # '-' key
		zoom -= Vector2.ONE * zoom_speed * delta
	zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

	if target:
		global_position = target.global_position + follow_offset
