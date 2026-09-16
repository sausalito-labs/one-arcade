class_name Player
extends CharacterBody2D

# Keep this in sync with the AnimationTree's state names.
const States = {
	IDLE = "idle",
	WALK = "walk",
	RUN = "run",
	FLY = "fly",
	FALL = "fall",
	BACKUP = "backup",
	BACKUP_FAST = "backup_fast",
}

const WALK_SPEED = 200.0
const ACCELERATION_SPEED = WALK_SPEED * 6.0
const JUMP_VELOCITY = -400.0
## Maximum speed at which the player can fall.
const TERMINAL_VELOCITY = 400

var falling_slow: bool = false
var falling_fast: bool = false
var no_move_horizontal_time := 0.0

func _ready() -> void:
	# Work around Godot 4.3 bug #96553: the default (empty name) animation
	# library can fail to load due to a String/StringName hash mismatch.
	# Load the library with an explicit name so it survives export.
	var anim_lib := load("res://player_robot/animations.tres") as AnimationLibrary
	$AnimationPlayer.add_animation_library("main", anim_lib)
	$AnimationTree.active = true


func _physics_process(delta: float) -> void:
	var is_jumping: bool = false
	if Input.is_action_just_pressed(&"jump"):
		is_jumping = try_jump()
	elif Input.is_action_just_released(&"jump") and velocity.y < 0.0:
		# The player let go of jump early, reduce vertical momentum.
		velocity.y *= 0.6
	if Input.is_action_just_pressed(&"jab"):
		$AnimationTree["parameters/jab/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	# Fall.
	velocity.y = minf(TERMINAL_VELOCITY, velocity.y + get_gravity().y * delta)

	var direction := Input.get_axis(&"move_left", &"move_right") * WALK_SPEED
	velocity.x = move_toward(velocity.x, direction, ACCELERATION_SPEED * delta)

	if no_move_horizontal_time > 0.0:
		# After doing a hard fall, don't move for a short time.
		velocity.x = 0.0
		no_move_horizontal_time -= delta

	move_and_slide()

	# After applying our motion, update our animation to match.

	# Calculate falling speed for animation purposes.
	if velocity.y >= TERMINAL_VELOCITY:
		falling_fast = true
		falling_slow = false
	elif velocity.y > 300:
		falling_slow = true

	if is_jumping:
		$AnimationTree["parameters/jump/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

	if is_on_floor():
		# Most animations change when we run, land, or take off.
		if falling_fast:
			$AnimationTree["parameters/land_hard/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
			no_move_horizontal_time = 0.4
		elif falling_slow:
			$AnimationTree["parameters/land/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

		# The rig always faces right, so moving left is a backpedal.
		var moving_back := velocity.x < 0.0
		var speed: float = abs(velocity.x)
		if speed > 50:
			$AnimationTree["parameters/state/transition_request"] = States.BACKUP_FAST if moving_back else States.RUN
			$AnimationTree["parameters/run_timescale/scale"] = speed / 60
			$AnimationTree["parameters/backup_fast_timescale/scale"] = speed / 60
		elif velocity.x:
			$AnimationTree["parameters/state/transition_request"] = States.BACKUP if moving_back else States.WALK
			$AnimationTree["parameters/walk_timescale/scale"] = speed / 12
			$AnimationTree["parameters/backup_timescale/scale"] = speed / 12
		else:
			$AnimationTree["parameters/state/transition_request"] = States.IDLE

		falling_fast = false
		falling_slow = false
	else:
		if velocity.y > 0:
			$AnimationTree["parameters/state/transition_request"] = States.FALL
		else:
			$AnimationTree["parameters/state/transition_request"] = States.FLY



func try_jump() -> bool:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		return true

	return false
