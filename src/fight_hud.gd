class_name FightHud
extends CanvasLayer

## Arcade fight HUD: two mortal-combat-style health bars (P1 left, P2 right)
## with names above, plus a center round label and KO overlay.
## Layout is responsive: bar widths track the viewport so they span the
## device screen on desktop and mobile alike. Built from Control nodes only.

const MARGIN_F := 0.02
const CENTER_GAP_F := 0.04
const BAR_HEIGHT := 26.0
const BAR_TOP := 78.0
const NAME_TOP := 46.0
const BAR_COLORS := {1: Color("#e8305a"), 2: Color("#4aa8e0")}
const NAME_COLORS := {1: Color("#ffd23f"), 2: Color("#ffe8d6")}

var _fills: Dictionary = {}
var _frames: Dictionary = {}
var _names: Dictionary = {}
var _ko_label: Label
var _round_label: Label


func _ready() -> void:
	layer = 10
	_build()
	_relayout()
	get_viewport().size_changed.connect(_relayout)
	FightSystem.health_changed.connect(func(fid: int, hp: float) -> void:
		if _fills.has(fid):
			_update_fill(fid, hp)
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
	round.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	round.offset_top = 4
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
		if not is_left:
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		root.add_child(name_label)
		_names[fighter_id] = name_label

		var frame := ColorRect.new()
		frame.color = Color(0.08, 0.08, 0.1)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(frame)
		_frames[fighter_id] = frame

		var fill := ColorRect.new()
		fill.color = BAR_COLORS[fighter_id]
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


## Recompute layout after a resize: bars scale with the viewport so they
## always span the screen edge-to-edge with a small symmetric margin.
func _relayout() -> void:
	var bar_w: float = _bar_geometry()
	if bar_w <= 0.0:
		return

	var vw: float = get_viewport().get_visible_rect().size.x
	var margin: float = vw * MARGIN_F

	for fighter_id: int in [1, 2]:
		var is_left: bool = fighter_id == 1
		var x: float = margin if is_left else vw - margin - bar_w

		_frames[fighter_id].position = Vector2(x, BAR_TOP)
		_frames[fighter_id].size = Vector2(bar_w, BAR_HEIGHT)
		# Name label sits above its bar, full bar-width wide.
		_names[fighter_id].position = Vector2(x, NAME_TOP)
		_names[fighter_id].size = Vector2(bar_w, 22)

		var fill: ColorRect = _fills[fighter_id]
		fill.position = Vector2(x, BAR_TOP)
		fill.size = Vector2(bar_w, BAR_HEIGHT)
		# Anchor side that must stay fixed when the bar drains toward center:
		# P1 drains from the right (anchored left), P2 from the left (anchored right).
		fill.set_meta("anchor_x", x if is_left else vw - margin)
		_update_fill(fighter_id, FightSystem.health[fighter_id])


## One source of truth for bar geometry derived from the current viewport.
func _bar_geometry() -> float:
	var vw: float = get_viewport().get_visible_rect().size.x
	var margin: float = vw * MARGIN_F
	var gap: float = vw * CENTER_GAP_F
	return (vw - margin * 2.0 - gap) / 2.0


func _update_fill(fighter_id: int, hp: float) -> void:
	var fill: ColorRect = _fills[fighter_id]
	var bar_w: float = _bar_geometry()
	var new_width: float = bar_w * (hp / FightSystem.MAX_HEALTH)
	var anchor_x: float = fill.get_meta("anchor_x")
	fill.position.x = anchor_x - new_width if fighter_id == 2 else anchor_x
	fill.size.x = new_width


func _show_ko(koed_id: int) -> void:
	var winner: int = 1 if koed_id == 2 else 2
	_ko_label.text = "%s WINS\nKO!" % ("P1" if winner == 1 else "P2")


func _hide_ko() -> void:
	_ko_label.text = ""
	_round_label.text = "ROUND 1"
