extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

@onready var animated_sprite = $AnimatedSprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#var direction = 1
var do_jump = false
var _is_on_floor = true
var alive = true

@export var input: PlayerInput
@export var synced_position := Vector2()

@export var player_id := 1:
	set(id):
		player_id = id
		input.set_multiplayer_authority(id)
		#%InputSynchronizer.set_multiplayer_authority(id)

func _ready():
	position = synced_position
	
	#if str(name).is_valid_int():
		#%InputSynchronizer.set_multiplayer_authority(str(name).to_int())
	#
	if multiplayer.get_unique_id() == player_id:
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false

func _apply_animations(delta):
	var direction = input.input_direction
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations
	if _is_on_floor:
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

func _apply_movement_from_input(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if do_jump and is_on_floor():
		velocity.y = JUMP_VELOCITY
		do_jump = false

	# Get the input direction: -1, 0, 1
	var direction = input.input_direction# %InputSynchronizer.input_direction
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	synced_position = position

func _physics_process(delta):
	if is_multiplayer_authority():#multiplayer.is_server():
		if not alive && is_on_floor():
			_set_alive()
		
		_is_on_floor = is_on_floor()
		_apply_movement_from_input(delta)
		
		if MultiplayerManager.host_mode_enabled: # still need animations in host mode
			_apply_animations(delta)
	else:
		position = synced_position
		_apply_animations(delta)

func mark_dead():
	print("Mark player dead!")
	alive = false
	$CollisionShape2D.set_deferred("disabled", true)
	$RespawnTimer.start()

func _respawn():
	print("Respawned!")
	position = MultiplayerManager.respawn_point
	$CollisionShape2D.set_deferred("disabled", false)

func _set_alive():
	print("alive again!")
	alive = true
	Engine.time_scale = 1.0





