extends CharacterBody2D

@export var move_speed: float = 300.0
@export var gravity: float = 1200.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var visual_group: Node2D = $VisualGroup

enum State { IDLE, WALK, ATTACK }
var state: State = State.IDLE
var opponent: Node2D = null

const LEAD_ARM_PATH := "VisualGroup/LeadArmPivot"
const LEAD_FOREARM_PATH := "VisualGroup/LeadArmPivot/UpperArm/ForearmPivot"
const REAR_ARM_PATH := "VisualGroup/RearArmPivot"
const REAR_FOREARM_PATH := "VisualGroup/RearArmPivot/UpperArm/ForearmPivot"
const LEAD_LEG_PATH := "VisualGroup/LeadLegPivot"
const LEAD_SHIN_PATH := "VisualGroup/LeadLegPivot/Thigh/ShinPivot"
const REAR_LEG_PATH := "VisualGroup/RearLegPivot"
const REAR_SHIN_PATH := "VisualGroup/RearLegPivot/Thigh/ShinPivot"

func _ready() -> void:
	build_animations()
	anim_player.animation_finished.connect(_on_animation_finished)
	play_anim("idle")

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	face_opponent()

	if state == State.ATTACK:
		velocity.x = 0.0
		move_and_slide()
		return

	var input_x := 0.0
	if Input.is_key_pressed(KEY_A):
		input_x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_x += 1.0

	if input_x != 0.0:
		state = State.WALK
		velocity.x = input_x * move_speed
		play_anim("walk")
	else:
		state = State.IDLE
		velocity.x = 0.0
		play_anim("idle")

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J and state != State.ATTACK:
			trigger_jab()

func trigger_jab() -> void:
	state = State.ATTACK
	velocity.x = 0.0
	play_anim("jab")

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "jab":
		state = State.IDLE
		play_anim("idle")

func face_opponent() -> void:
	if not opponent:
		return
	var to_opponent := opponent.global_position.x - global_position.x
	if to_opponent > 0.0:
		visual_group.scale.x = 1.0
	elif to_opponent < 0.0:
		visual_group.scale.x = -1.0

func play_anim(anim_name: String) -> void:
	if not anim_player:
		return
	if anim_player.current_animation == anim_name:
		return
	anim_player.play(anim_name)

func build_animations() -> void:
	var lib := anim_player.get_animation_library("")
	if not lib:
		lib = AnimationLibrary.new()
		anim_player.add_animation_library("", lib)
	lib.add_animation("idle", build_idle_animation())
	lib.add_animation("walk", build_walk_animation())
	lib.add_animation("jab", build_jab_animation())

func build_idle_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR

	var visual_pos_track := add_position_track(anim, "VisualGroup")
	anim.track_insert_key(visual_pos_track, 0.0, Vector2(0.0, -70.0))
	anim.track_insert_key(visual_pos_track, 0.5, Vector2(0.0, -72.0))
	anim.track_insert_key(visual_pos_track, 1.0, Vector2(0.0, -70.0))

	var torso_rot_track := add_rotation_track(anim, "VisualGroup/Torso")
	anim.track_insert_key(torso_rot_track, 0.0, deg_to_rad(-1.0))
	anim.track_insert_key(torso_rot_track, 0.5, deg_to_rad(1.0))
	anim.track_insert_key(torso_rot_track, 1.0, deg_to_rad(-1.0))

	set_rest_pose_keys(anim, 0.0)
	set_rest_pose_keys(anim, 1.0)

	return anim

func build_walk_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.6
	anim.loop_mode = Animation.LOOP_LINEAR

	var visual_pos_track := add_position_track(anim, "VisualGroup")
	anim.track_insert_key(visual_pos_track, 0.0, Vector2(0.0, -70.0))
	anim.track_insert_key(visual_pos_track, 0.3, Vector2(0.0, -76.0))
	anim.track_insert_key(visual_pos_track, 0.6, Vector2(0.0, -70.0))

	var lead_leg_track := add_rotation_track(anim, LEAD_LEG_PATH)
	anim.track_insert_key(lead_leg_track, 0.0, deg_to_rad(25.0))
	anim.track_insert_key(lead_leg_track, 0.3, deg_to_rad(-25.0))
	anim.track_insert_key(lead_leg_track, 0.6, deg_to_rad(25.0))

	var lead_shin_track := add_rotation_track(anim, LEAD_SHIN_PATH)
	anim.track_insert_key(lead_shin_track, 0.0, deg_to_rad(-10.0))
	anim.track_insert_key(lead_shin_track, 0.15, deg_to_rad(-40.0))
	anim.track_insert_key(lead_shin_track, 0.3, deg_to_rad(0.0))
	anim.track_insert_key(lead_shin_track, 0.6, deg_to_rad(-10.0))

	var rear_leg_track := add_rotation_track(anim, REAR_LEG_PATH)
	anim.track_insert_key(rear_leg_track, 0.0, deg_to_rad(-25.0))
	anim.track_insert_key(rear_leg_track, 0.3, deg_to_rad(25.0))
	anim.track_insert_key(rear_leg_track, 0.6, deg_to_rad(-25.0))

	var rear_shin_track := add_rotation_track(anim, REAR_SHIN_PATH)
	anim.track_insert_key(rear_shin_track, 0.0, deg_to_rad(0.0))
	anim.track_insert_key(rear_shin_track, 0.3, deg_to_rad(-10.0))
	anim.track_insert_key(rear_shin_track, 0.45, deg_to_rad(-40.0))
	anim.track_insert_key(rear_shin_track, 0.6, deg_to_rad(0.0))

	var lead_arm_track := add_rotation_track(anim, LEAD_ARM_PATH)
	anim.track_insert_key(lead_arm_track, 0.0, deg_to_rad(15.0))
	anim.track_insert_key(lead_arm_track, 0.3, deg_to_rad(-15.0))
	anim.track_insert_key(lead_arm_track, 0.6, deg_to_rad(15.0))

	var rear_arm_track := add_rotation_track(anim, REAR_ARM_PATH)
	anim.track_insert_key(rear_arm_track, 0.0, deg_to_rad(-15.0))
	anim.track_insert_key(rear_arm_track, 0.3, deg_to_rad(15.0))
	anim.track_insert_key(rear_arm_track, 0.6, deg_to_rad(-15.0))

	return anim

func build_jab_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.28

	var visual_pos_track := add_position_track(anim, "VisualGroup")
	anim.track_insert_key(visual_pos_track, 0.0, Vector2(0.0, -70.0))
	anim.track_insert_key(visual_pos_track, 0.08, Vector2(8.0, -70.0))
	anim.track_insert_key(visual_pos_track, 0.28, Vector2(0.0, -70.0))

	set_rest_pose_keys(anim, 0.0)
	set_rest_pose_keys(anim, 0.28)

	var lead_arm_track := add_rotation_track(anim, LEAD_ARM_PATH)
	anim.track_insert_key(lead_arm_track, 0.0, deg_to_rad(10.0))
	anim.track_insert_key(lead_arm_track, 0.08, deg_to_rad(-60.0))
	anim.track_insert_key(lead_arm_track, 0.28, deg_to_rad(10.0))

	var lead_forearm_track := add_rotation_track(anim, LEAD_FOREARM_PATH)
	anim.track_insert_key(lead_forearm_track, 0.0, deg_to_rad(30.0))
	anim.track_insert_key(lead_forearm_track, 0.08, deg_to_rad(0.0))
	anim.track_insert_key(lead_forearm_track, 0.28, deg_to_rad(30.0))

	var rear_arm_track := add_rotation_track(anim, REAR_ARM_PATH)
	anim.track_insert_key(rear_arm_track, 0.0, deg_to_rad(-10.0))
	anim.track_insert_key(rear_arm_track, 0.08, deg_to_rad(-30.0))
	anim.track_insert_key(rear_arm_track, 0.28, deg_to_rad(-10.0))

	return anim

func set_rest_pose_keys(anim: Animation, time: float) -> void:
	anim.track_insert_key(add_rotation_track(anim, LEAD_ARM_PATH), time, deg_to_rad(10.0))
	anim.track_insert_key(add_rotation_track(anim, LEAD_FOREARM_PATH), time, deg_to_rad(30.0))
	anim.track_insert_key(add_rotation_track(anim, REAR_ARM_PATH), time, deg_to_rad(-10.0))
	anim.track_insert_key(add_rotation_track(anim, REAR_FOREARM_PATH), time, deg_to_rad(30.0))
	anim.track_insert_key(add_rotation_track(anim, LEAD_LEG_PATH), time, deg_to_rad(5.0))
	anim.track_insert_key(add_rotation_track(anim, LEAD_SHIN_PATH), time, deg_to_rad(-5.0))
	anim.track_insert_key(add_rotation_track(anim, REAR_LEG_PATH), time, deg_to_rad(-5.0))
	anim.track_insert_key(add_rotation_track(anim, REAR_SHIN_PATH), time, deg_to_rad(5.0))

func add_rotation_track(anim: Animation, node_path: String) -> int:
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath(node_path + ":rotation"))
	anim.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)
	anim.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
	return track

func add_position_track(anim: Animation, node_path: String) -> int:
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath(node_path + ":position"))
	anim.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)
	anim.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
	return track
