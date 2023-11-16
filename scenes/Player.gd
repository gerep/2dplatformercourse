extends KinematicBody2D

signal died

var playerDeathScene = preload("res://scenes/PlayerDeath.tscn")

enum State { NORMAL, DASHING }

export (int, LAYERS_2D_PHYSICS) var dashHazardMask

var gravity = 1000
var velocity = Vector2.ZERO
var maxHorizontalSpeed = 140
var maxDashSpeed = 500
var minDashSpeed = 200
var horizontalAcceleration = 2000
var jumpSpeed = 320
var jumpTerminationMultiplier = 4
var hasDoubleJump = false
var hasDash = false
var currentState = State.NORMAL
var isStateNew = true
var defaulHazardMask = 0
var isDying = false

func _ready():
	$HazzardArea.connect("area_entered", self, "on_hazzard_area_entered")
	defaulHazardMask = $HazzardArea.collision_mask

func _process(delta):
	match currentState:
		State.NORMAL:
			process_normal(delta)
		State.DASHING:
			process_dash(delta)

	isStateNew = false

func change_state(newState):
	currentState = newState
	isStateNew = true

func process_dash(delta):
	if isStateNew:
		$DashParticles.emitting = true
		$DashArea/CollisionShape2D.disabled = false
		$HazzardArea.collision_layer = dashHazardMask
		$AnimatedSprite.play("jump")
		var modVector = get_movement_vector()
		var velocityMod = 1
		if modVector.x != 0:
			velocityMod = sign(modVector.x)
		else:
			velocityMod = 1 if $AnimatedSprite.flip_h else -1

		# Set the velocity only on the first frame.
		velocity = Vector2(maxDashSpeed * velocityMod, 0)

	velocity = move_and_slide(velocity, Vector2.UP)
	velocity.x = lerp(0, velocity.x, pow(2, -8 * delta))

	if abs(velocity.x) < minDashSpeed:
		call_deferred("change_state", State.NORMAL)

func process_normal(delta):
	if isStateNew:
		$DashParticles.emitting = false
		$DashArea/CollisionShape2D.disabled = true
		$HazzardArea.collision_layer = defaulHazardMask

	var moveVector = get_movement_vector()

	# Gradually increase horizontal movement.
	velocity.x += moveVector.x * horizontalAcceleration * delta
	if moveVector.x == 0:		
		# Framerate independent lerp.
		velocity.x = lerp(0, velocity.x, pow(2, -50 * delta))

	# Limit the x value to the maxHorizontalSpeed to avoid infinite accelaration.
	velocity.x = clamp(velocity.x, -maxHorizontalSpeed, maxHorizontalSpeed)

	if (moveVector.y < 0 and (is_on_floor() or !$CoyoteTimer.is_stopped() or hasDoubleJump)):
		velocity.y = moveVector.y * jumpSpeed
		if !is_on_floor() and $CoyoteTimer.is_stopped():
			hasDoubleJump = false
		$CoyoteTimer.stop()

	# Holding the jump key will make the player jump higher.
	if velocity.y < 0 && !Input.is_action_pressed("jump"):
		velocity.y += gravity * jumpTerminationMultiplier * delta
	else:
		velocity.y += gravity * delta

	var wasOnFloor = is_on_floor()
	velocity = move_and_slide(velocity, Vector2.UP)

	if wasOnFloor and !is_on_floor():
		$CoyoteTimer.start()

	if is_on_floor():
		hasDoubleJump = true
		hasDash = true

	if hasDash and Input.is_action_just_pressed("dash"):
		# Wait for the current process to finish before changing the current state.
		call_deferred("change_state", State.DASHING)
		hasDash = false

	update_animation()

func get_movement_vector():
	var moveVector = Vector2.ZERO
	moveVector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	moveVector.y = -1 if Input.is_action_just_pressed("jump") else 0
	return moveVector

func update_animation():
	var moveVector = get_movement_vector()

	if !is_on_floor():
		$AnimatedSprite.play("jump")
	elif moveVector.x != 0:
		$AnimatedSprite.play("run")
	else:
		$AnimatedSprite.play("idle")

	if moveVector.x != 0:
		$AnimatedSprite.flip_h = true if moveVector.x > 0 else false

func kill():
	if isDying:
		return

	isDying = true
	var playerDeathInstance = playerDeathScene.instance()
	get_parent().add_child_below_node(self, playerDeathInstance)
	playerDeathInstance.global_position = global_position
	playerDeathInstance.velocity = velocity

	emit_signal("died")

func on_hazzard_area_entered(_area2d):
	call_deferred("kill")
