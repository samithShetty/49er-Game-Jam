class_name Player
extends Actor


# warning-ignore:unused_signal
signal collect_coin()

const FLOOR_DETECT_DISTANCE = 20.0

export(String) var action_suffix = ""

onready var platform_detector = $PlatformDetector
onready var animation_player = $AnimationPlayer
onready var shoot_timer = $ShootAnimation
onready var sprite = $Sprite
onready var sound_jump = $Jump
onready var gun = sprite.get_node(@"Gun")

var my_damaging_layer: = 4
var scary_monster_layer: = 6
var hunger_drain: = 1
var curr_hunger: = 100
var max_hunger: = 100
var has_jump:bool = true
var dash_timer:float = 0

func _ready():
	# Static types are necessary here to avoid warnings.
	var camera: Camera2D = $Camera
	if action_suffix == "_p1":
		camera.custom_viewport = $"../.."
		yield(get_tree(), "idle_frame")
		camera.make_current()
	elif action_suffix == "_p2":
		var viewport: Viewport = $"../../../../ViewportContainer2/Viewport2"
		viewport.world_2d = ($"../.." as Viewport).world_2d
		camera.custom_viewport = viewport
		yield(get_tree(), "idle_frame")
		camera.make_current()

# These 2 functions theoreticallyapply / remove a penalty to the player's hunger Drain based
func _on_DamageDetector_body_entered(body: PhysicsBody2D) -> void:
	
	if body.get_collision_layer() == my_damaging_layer:
		hunger_drain *= 3 
	elif body.get_collision_layer() == scary_monster_layer+1:
		hunger_drain *= 10 
	return

func _on_DamageDetector_area_exited(area: Area2D) -> void:
	
	if area.get_collision_layer() == my_damaging_layer:
		hunger_drain /= 3 
	elif area.get_collision_layer() == scary_monster_layer:
		hunger_drain /= 10 
	return
# Physics process is a built-in loop in Godot.
# If you define _physics_process on a node, Godot will call it every frame.

# We use separate functions to calculate the direction and velocity to make this one easier to read.
# At a glance, you can see that the physics process loop:
# 1. Calculates the move direction.
# 2. Calculates the move velocity.
# 3. Moves the character.
# 4. Updates the sprite direction.
# 5. Shoots bullets.
# 6. Updates the animation.

# Splitting the physics process logic into functions not only makes it
# easier to read, it help to change or improve the code later on:
# - If you need to change a calculation, you can use Go To -> Function
#   (Ctrl Alt F) to quickly jump to the corresponding function.
# - If you split the character into a state machine or more advanced pattern,
#   you can easily move individual functions.
func _physics_process(_delta):
	# Play jump sound
	if Input.is_action_just_pressed("jump" + action_suffix) and has_jump:
		sound_jump.play()
	
	var direction = get_direction()

	#slows x movement
	_velocity.x = 0.0
		#conditionally slows y movement
	if _velocity.y < 0:
		_velocity.y *= 0
			
	var is_jump_interrupted = Input.is_action_just_released("jump" + action_suffix) and _velocity.y < 0.0
	_velocity = calculate_move_velocity(_velocity, direction, speed, is_jump_interrupted)
	
	if dash_timer > 0:
		dash_timer -= _delta if not is_on_wall() else .5
		if dash_timer > 0.8:
			_velocity.x += 500 * sprite.scale.x
			_velocity.y = 0
		
	elif Input.is_action_just_pressed("dash" + action_suffix):
		dash_timer = 1
		_velocity.x += 500 * sprite.scale.x
		_velocity.y = 0
	
	var is_on_platform = platform_detector.is_colliding()
	_velocity = move_and_slide(
		_velocity, FLOOR_NORMAL, not is_on_platform, 4, 0.9, false
	)
	
	# When the character’s direction changes, we want to to scale the Sprite accordingly to flip it.
	# This will make Robi face left or right depending on the direction you move.
	if direction.x != 0:
		if direction.x > 0:
			sprite.scale.x = 1
		else:
			sprite.scale.x = -1

	# We use the sprite's scale to store Robi’s look direction which allows us to shoot
	# bullets forward.
	# There are many situations like these where you can reuse existing properties instead of
	# creating new variables.
	var is_shooting = false
	if Input.is_action_just_pressed("shoot" + action_suffix):
		is_shooting = gun.shoot(sprite.scale.x)

	var animation = get_new_animation(is_shooting)
	if animation != animation_player.current_animation and shoot_timer.is_stopped():
		if is_shooting:
			shoot_timer.start()
		animation_player.play(animation)
		
	# Only possible when occupying a monster's space
	while hunger_drain > 1:
		
		#slows x movement
		_velocity.x = 0.0
		#conditionally slows y movement
		if _velocity.y < 0:
			_velocity.y *= 0
	
	if curr_hunger < 1:
		die()


func get_direction():
	if is_on_floor() or is_on_wall():
		has_jump = true
		
	var y_dir = 0;
	
	if Input.is_action_just_pressed("jump" + action_suffix):
		if is_on_floor():
			y_dir = -1
		elif has_jump:
			y_dir = -1
			has_jump = false
	
	if Input.is_action_just_pressed("fastfall" + action_suffix) and not is_on_floor():
		y_dir = 1
			
		
	return Vector2(
		Input.get_action_strength("move_right" + action_suffix) - Input.get_action_strength("move_left" + action_suffix),
		y_dir
	)


# This function calculates a new velocity whenever you need it.
# It allows you to interrupt jumps.
func calculate_move_velocity(
		linear_velocity,
		direction,
		speed,
		is_jump_interrupted
	):
	var velocity = linear_velocity
	
	velocity.x = speed.x * direction.x
	if direction.y != 0.0:
		velocity.y = speed.y * direction.y
	if is_jump_interrupted:
		# Decrease the Y velocity by multiplying it, but don't set it to 0
		# as to not be too abrupt.
		velocity.y *= 0.6
	return velocity


func get_new_animation(is_shooting = false):
	var animation_new = ""
	if is_on_floor():
		if abs(_velocity.x) > 0.1:
			animation_new = "run"
		else:
			animation_new = "idle"
	else:
		if _velocity.y > 0:
			animation_new = "falling"
		else:
			animation_new = "jumping"
	if is_shooting:
		animation_new += "_weapon"
	return animation_new

func take_damage(damage: int) -> void:
	curr_hunger -= damage

func die() -> void:
	
	queue_free()
