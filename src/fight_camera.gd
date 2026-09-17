extends Camera2D

## The camera that frames the ring: centers on the midpoint between the two
## fighters and continuously adjusts zoom so both stay in frame as they move.

@export var fighter_a_path: NodePath
@export var fighter_b_path: NodePath
## World-space (unscaled) padding kept between a fighter and the screen edge.
@export var frame_margin: float = 60.0
@export var min_zoom: float = 1.5
@export var max_zoom: float = 4.0
@export var follow_speed: float = 4.0
## Hard clamping box (matches the ring bounds) so the camera never shows
## outside the ring.
@export var clamp_left: float = -600.0
@export var clamp_right: float = 600.0
@export var clamp_top: float = 200.0
@export var clamp_bottom: float = 700.0
## World-space Y of the floor line the fighters stand on. The camera keeps
## this line pinned just above the bottom of the frame instead of centering
## the fighters, so the floor reads as a solid stage rather than a floating
## strip with empty void above and below it.
@export var floor_y: float = 500.0
## Extra world-space visible below the floor line (a sliver of stage under
## the fighters). Keep small so there is no "floating floor" gap.
@export var floor_pad: float = 12.0

var fighter_a: Node2D
var fighter_b: Node2D

func _ready() -> void:
	fighter_a = get_node_or_null(fighter_a_path)
	fighter_b = get_node_or_null(fighter_b_path)
	if fighter_a and fighter_b:
		global_position = (fighter_a.global_position + fighter_b.global_position) * 0.5
	elif fighter_a:
		global_position = fighter_a.global_position
	_apply_y_framing()

func _process(delta: float) -> void:
	if not fighter_a or not fighter_b:
		return

	var a := fighter_a.global_position
	var b := fighter_b.global_position
	var midpoint := (a + b) * 0.5

	# Zoom to frame both fighters. The viewport shows screen_size / zoom world
	# units, so solve zoom = screen_width / (distance + margins).
	var screen := get_viewport_rect().size.x
	var span := absf(a.x - b.x) + frame_margin * 2.0
	var target_zoom: float = clampf(screen / span, min_zoom, max_zoom)
	zoom = zoom.lerp(Vector2.ONE * target_zoom, 1.0 - exp(-follow_speed * delta))

	# Only X tracks the fighters; Y is pinned by _apply_y_framing (floor near
	# the bottom of the frame), so the lerp must not mess with Y.
	var half_w := (get_viewport_rect().size.x / 2.0) / zoom.x
	global_position.x = lerpf(global_position.x, midpoint.x, 1.0 - exp(-follow_speed * delta))
	global_position.x = clampf(global_position.x, clamp_left + half_w, clamp_right - half_w)
	_apply_y_framing()


## Pin the bottom of the screen just below the floor line and keep Y there.
func _apply_y_framing() -> void:
	var half_h := (get_viewport_rect().size.y / 2.0) / zoom.y
	global_position.y = clampf(floor_y + floor_pad - half_h, clamp_top + half_h, clamp_bottom - half_h)
