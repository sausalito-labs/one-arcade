class_name FightHud
extends CanvasLayer

## Arcade fight HUD: two mortale-kombat-style health bars (P1 left, P2 right)
## with names above, plus a center round label and KO overlay.
## Built entirely from Control nodes; no textures required.

const BAR_WIDTH := 460.0
const BAR_HEIGHT := 24.0
const BAR_TOP := 30.0
const BAR_COLORS := {1: Color("#e8305a"), 2: Color("#4aa8e0")}
const NAME_COLORS := {1: Color("#ffd23f"), 2: Color("#ffe8d6")}

var _fills: Dictionary = {}
var _names: Dictionary = {}
var _ko_label: Label
var _round_label: Label


func _ready() -> void:
	layer = 10
	_build()
	FightSystem.health_changed.connect(func(fid: int, hp: float) -> void:
		if _fills.has(fid):
			var new_width: float = BAR_WIDTH * (hp / FightSystem.MAX_HEALTH)
			_fills[fid].size.x = new_width
			# P2 bar shrinks from the left (toward center) — shift position right.
			if fid == 2:
				_fills[fid].position.x = 1280.0 - 20.0 - new_width
	)
	FightSystem.fighter_ko.connect(func(fid: int) -> void:
		_show_ko(fid)
	)
	FightSystem.round_reset.connect(_hide_ko)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var round := Label.new()
	round.text = "ROUND 1"
	round.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round.add_theme_font_size_override("font_size", 26)
	round.add_theme_color_override("font_color", Color("#ffffff"))
	round.add_theme_color_override("font_outline_color", Color("#000000"))
	round.add_theme_constant_override("outline_size", 6)
	round.position = Vector2(0, 4)
	round.size = Vector2(1280, 30)
	round.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(round)
	_round_label = round

	for fighter_id: int in [1, 2]:
		var is_left: bool = fighter_id == 1

		var name_label := Label.new()
		name_label.text = "P%d" % fighter_id
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_color_override("font_color", NAME_COLORS[fighter_id])
		name_label.add_theme_color_override("font_outline_color", Color("#000000"))
		name_label.add_theme_constant_override("outline_size", 5)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if is_left:
			name_label.position = Vector2(24, 8)
		else:
			name_label.size = Vector2(BAR_WIDTH, 24)
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			name_label.position = Vector2(1280 - 24 - BAR_WIDTH, 8)
		root.add_child(name_label)
		_names[fighter_id] = name_label

		# Bar frame.
		var frame := ColorRect.new()
		frame.color = Color(0.08, 0.08, 0.1)
		if is_left:
			frame.position = Vector2(20, BAR_TOP)
		else:
			frame.position = Vector2(1280 - 20 - BAR_WIDTH, BAR_TOP)
		frame.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(frame)

		# HP fill. For P1 it drains from the right; anchor to the left edge.
		var fill := ColorRect.new()
		fill.color = BAR_COLORS[fighter_id]
		fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
		if is_left:
			fill.position = Vector2(20, BAR_TOP)
		else:
			fill.position = Vector2(1280 - 20 - BAR_WIDTH, BAR_TOP)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(fill)
		_fills[fighter_id] = fill

	_ko_label = Label.new()
	_ko_label.text = ""
	_ko_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ko_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ko_label.add_theme_font_size_override("font_size", 90)
	_ko_label.add_theme_color_override("font_color", Color("#ff2244"))
	_ko_label.add_theme_color_override("font_outline_color", Color("#000000"))
	_ko_label.add_theme_constant_override("outline_size", 12)
	_ko_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ko_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_ko_label)


func _show_ko(koed_id: int) -> void:
	var winner: int = 1 if koed_id == 2 else 2
	_ko_label.text = "%s WINS\nKO!" % ("P1" if winner == 1 else "P2")


func _hide_ko() -> void:
	_ko_label.text = ""
	_round_label.text = "ROUND 1"