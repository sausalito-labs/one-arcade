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

## Whether this fighter reads player input. Disabled fighters (e.g. P2 as a
## placeholder/AI) just stand still.
@export var controllable := true
## -1 faces left (mirrored sprite), 1 faces right. The animation data is authored
## for a right-facing rig; mirroring the Sprite2D flips it cleanly.
@export var facing := 1
## 1 or 2. Identifies which HUD bar / health pool this fighter owns.
@export var fighter_id := 1

var falling_slow: bool = false
var falling_fast: bool = false
var no_move_horizontal_time := 0.0

## Current HP, owned by FightSystem (stored here for direct reads).
var health: float = FightSystem.MAX_HEALTH
## Remaining time the fighter is stunned and cannot act.
var hitstun_remaining := 0.0
## Knockback velocity applied while in hitstun.
var knockback_velocity := 0.0
## Active hitbox is armed and may damage the opponent (during jab windup-out).
var hitbox_active := false

@onready var _hitbox := $Hitbox
@onready var _hurtbox := $Hurtbox

func _ready() -> void:
	# Flip horizontally for facing while preserving the x scale (the sprite's
	# base scale is non-1, so we multiply rather than overwrite).
	var sprite_scale: Vector2 = $Sprite2D.scale
	sprite_scale.x = absf(sprite_scale.x) * facing
	$Sprite2D.scale = sprite_scale
	# Work around Godot 4.3 bug #96553: the default (empty name) animation
	# library can fail to load due to a String/StringName hash mismatch.
	# Load the library with an explicit name so it survives export.
	var anim_lib := load("res://player_robot/animations.tres") as AnimationLibrary
	$AnimationPlayer.add_animation_library("main", anim_lib)
	$AnimationTree.active = true

	# Flip the hitbox so it extends ahead of the fighter; hurtbox stays centered.
	_hitbox.position = Vector2(7 * facing, -20)
	_hitbox.monitoring = false
	# The hurtbox area needs to know which fighter owns it so the hitbox can
	# map "area touched" back onto a victim even when both fighters share the
	# same scene template.
	if _hurtbox:
		_hurtbox.set_meta("owner", self)

	add_to_group("fighters")
	FightSystem.register_fighter(self)
	# Keep the stored health in sync with FightSystem (the source of truth).
	FightSystem.health_changed.connect(func(_id: int, hp: float) -> void:
		health = hp
	)
	if _hitbox:
		_hitbox.area_entered.connect(_on_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	var is_jumping: bool = false

	# Hitstun: count down; while stunned the fighter cannot act or move on its own.
	if hitstun_remaining > 0.0:
		hitstun_remaining -= delta
		velocity.x = knockback_velocity
		knockback_velocity = move_toward(knockback_velocity, 0.0, 600.0 * delta)
	elif controllable:
		if Input.is_action_just_pressed(&"jump"):
			is_jumping = try_jump()
		elif Input.is_action_just_released(&"jump") and velocity.y < 0.0:
			# The player let go of jump early, reduce vertical momentum.
			velocity.y *= 0.6
		if Input.is_action_just_pressed(&"jab"):
			$AnimationTree["parameters/jab/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
			arm_hitbox()

	# Fall.
	velocity.y = minf(TERMINAL_VELOCITY, velocity.y + get_gravity().y * delta)

	var direction := 0.0
	if controllable and hitstun_remaining <= 0.0:
		direction = Input.get_axis(&"move_left", &"move_right") * WALK_SPEED
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


## Arm the hitbox for the active frames of the jab. The box stays live until
## the punch retract; a short-lived timer disarms it.
func arm_hitbox() -> void:
	if hitbox_active:
		return
	hitbox_active = true
	_hitbox.monitoring = true
	# Active window is 0.08s->0.48s of the jab; 0.34s of box life is plenty.
	get_tree().create_timer(0.34).timeout.connect(func() -> void:
		hitbox_active = false
		_hitbox.monitoring = false
	)


## Our hitbox overlapped another fighter's hurtbox area.
func _on_hitbox_area_entered(area: Area2D) -> void:
	# Ignore our own hurtbox and non-fighter areas.
	if not area.has_meta("owner"):
		return
	var victim: Node2D = area.get_meta("owner")
	if victim == self:
		return
	FightSystem.on_attack_connected(self, victim)


## This fighter was struck.
func get_hit(knockback: float) -> void:
	hitstun_remaining = FightSystem.HITSTUN_TIME
	knockback_velocity = knockback
	# Brief hit flash: tint the sprite, then restore.
	var sw := create_tween()
	sw.tween_property($Sprite2D, "modulate", Color(2.0, 1.0, 1.0, 1.0), 0.04)
	sw.tween_property($Sprite2D, "modulate", Color.WHITE, 0.18)


func reset_fighter() -> void:
	health = FightSystem.MAX_HEALTH
	hitstun_remaining = 0.0
	knockback_velocity = 0.0
	hitbox_active = false
	_hitbox.monitoring = false
