class_name TouchControls
extends CanvasLayer

## Mobile-only on-screen controls: a d-pad (left/right) on the bottom-left
## and jab/jump buttons on the bottom-right. Hidden on desktop/keyboard.
## Feeds the same Input actions the keyboard drives, so the player code is
## untouched. Pure Control nodes; no textures.

const PAD_BTN := 72.0
const ACT_BTN := 88.0
const CORNER_MARGIN := 36.0
const BTN_GAP := 16.0

var _left: Button
var _right: Button
var _jab: Button
var _jump: Button


func _ready() -> void:
	layer = 20
	_build()
	visible = _is_touch_device()
	get_viewport().size_changed.connect(_relayout)


func _is_touch_device() -> bool:
	# Web: primary pointer is coarse on phones/tablets, fine on desktops.
	# This is the reliable "is this a phone" signal (better than maxTouchPoints,
	# which is >0 on touch-capable laptops too).
	if OS.has_feature("web"):
		var coarse: bool = JavaScriptBridge.eval("window.matchMedia('(pointer: coarse)').matches")
		if coarse:
			return true
	# Native fallback (mobile builds/renderer): trust the touchscreen flag.
	return DisplayServer.is_touchscreen_available()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# D-pad: left/right. Semi-transparent so they don't hide the action.
	_left = _make_pad("◀", Color(1, 1, 1, 0.22))
	_left.button_down.connect(func() -> void: Input.action_press(&"move_left"))
	_left.button_up.connect(func() -> void: Input.action_release(&"move_left"))
	_right = _make_pad("▶", Color(1, 1, 1, 0.22))
	_right.button_down.connect(func() -> void: Input.action_press(&"move_right"))
	_right.button_up.connect(func() -> void: Input.action_release(&"move_right"))
	root.add_child(_left)
	root.add_child(_right)

	# Action buttons: jab (punch) and jump, right thumb area.
	_jab = _make_act("JAB", Color("#e8305a"))
	_jab.pressed.connect(func() -> void:
		Input.action_press(&"jab")
		# Hold the pressed state long enough for a clean is_action_just_pressed
		# frame, then release so a fresh tap registers as a new press.
		get_tree().create_timer(0.12).timeout.connect(func() -> void:
			Input.action_release(&"jab")
		)
	)
	_jump = _make_act("JUMP", Color("#ffd23f"))
	_jump.pressed.connect(func() -> void: Input.action_press(&"jump"))
	_jump.button_up.connect(func() -> void: Input.action_release(&"jump"))
	root.add_child(_jab)
	root.add_child(_jump)

	_relayout()


func _make_pad(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 34)
	b.custom_minimum_size = Vector2(PAD_BTN, PAD_BTN)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(2)
	sb.border_color = Color(1, 1, 1, 0.35)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	b.add_theme_stylebox_override("normal", sb)
	return b


func _make_act(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 26)
	b.custom_minimum_size = Vector2(ACT_BTN, ACT_BTN)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, 0.7)
	sb.set_corner_radius_all(44)
	sb.set_border_width_all(3)
	sb.border_color = color
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	b.add_theme_stylebox_override("normal", sb)
	return b


## Anchor the clusters to the bottom corners, scaled to the viewport width so
## they stay thumb-friendly in landscape and portrait.
func _relayout() -> void:
	var vw: float = get_viewport().get_visible_rect().size.x
	var vh: float = get_viewport().get_visible_rect().size.y
	var scale: float = clampf(vw / 1280.0, 0.7, 1.4)
	var pad: float = PAD_BTN * scale
	var act: float = ACT_BTN * scale
	var margin: float = CORNER_MARGIN * scale
	var gap: float = BTN_GAP * scale
	var bottom := vh - margin

	_left.position = Vector2(margin, bottom - pad)
	_right.position = Vector2(margin + pad + gap, bottom - pad)
	_jab.position = Vector2(vw - margin - act, bottom - act)
	_jump.position = Vector2(vw - margin - act * 2.0 - gap, bottom - act)
