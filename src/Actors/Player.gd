class_name Player
extends Actor


# warning-ignore:unused_signal
signal collect_coin()

const FLOOR_DETECT_DISTANCE = 20.0

export(String) var action_suffix = ""

onready var animation_player = $AnimationPlayer
onready var animated_sprite = $AnimatedSprite
onready var shoot_timer = $ShootAnimation
onready var sprite = $Sprite
onready var sound_jump = $Dash
onready var hunger_timer = $Hunger
onready var gun = sprite.get_node(@"Gun")
onready var game_over = get_node("/root/Game/Level/Portal2D")

var upgrade_progress: = Vector2(0,0)
var my_damaging_layer: = 8
var scary_monster_layer: = 6
var hunger_drain:float = 1
var curr_hunger:float = 15
export var hunger_int: float = curr_hunger
var max_hunger:float = 100
var has_jump:bool = true
var dash_timer:float = 0
var consuming:bool = false

var timeout


func _ready():
	# Static types are necessary here to avoid warnings.
	#hunger_timer.start(15)
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
	hunger_timer.connect("timeout()", self, "_on_Hunger_timeout()")
	
	
# These 2 functions theoreticallyapply / remove a penalty to the player's hunger Drain based
func _on_DamageDetector_body_entered(body: PhysicsBody2D) -> void:

	if body.get_collision_layer() == my_damaging_layer:
		hunger_drain += 2.0
	elif body.get_collision_layer() == scary_monster_layer+1:
		hunger_drain += 9.0 
	
	print("Entered", body.get_collision_layer(), hunger_drain)
	
	return

func _on_DamageDetector_body_exited(body: PhysicsBody2D) -> void:
	if body.get_collision_layer() == my_damaging_layer:
		hunger_drain -= 2.0 
	elif body.get_collision_layer() == scary_monster_layer:
		hunger_drain -= 9.0 
	print("Exited", body.get_collision_layer(), hunger_drain)
	
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
		
	if Input.is_action_just_pressed("consume" + action_suffix):
		consuming = true
		
	var direction = get_direction()
			
	var is_jump_interrupted = Input.is_action_just_released("jump" + action_suffix) and _velocity.y < 0.0
	_velocity = calculate_move_velocity(_velocity, direction, speed, is_jump_interrupted)
	
	if dash_timer > 0:
		dash_timer -= _delta if not is_on_wall() else .5
		if dash_timer > 0.8:
			_velocity.x += 500 * (-1 if animated_sprite.is_flipped_h() else 1)
			_velocity.y = 0
		
	elif Input.is_action_just_pressed("dash" + action_suffix):
		dash_timer = 1
		_velocity.x += 500 * (-1 if animated_sprite.is_flipped_h() else 1)
		_velocity.y = 0
		
	
	_velocity = move_and_slide(
		_velocity, FLOOR_NORMAL, true, 4, 0.9, false
	)
	# When the character’s direction changes, we want to to scale the Sprite accordingly to flip it.
	# This will make Robi face left or right depending on the direction you move.
	if direction.x != 0:
		if direction.x > 0:
			animated_sprite.set_flip_h(false)
		else:
			animated_sprite.set_flip_h(true)

	# We use the sprite's scale to store Robi’s look direction which allows us to shoot
	# bullets forward.
	# There are many situations like these where you can reuse existing properties instead of
	# creating new variables.
	var is_shooting = false
	if Input.is_action_just_pressed("shoot" + action_suffix):
		is_shooting = gun.shoot(sprite.scale.x)

	var animation = get_new_animation()
	
	animated_sprite.play(animation)

	if hunger_drain > 1:
		hunger_timer.start(hunger_timer.get_time_left() - _delta*hunger_drain)

	#hunger_timer.start(hunger_timer.get_time_left() - _delta*hunger_drain)
	print(curr_hunger)
	curr_hunger = hunger_int + (hunger_timer.get_time_left()*_delta*hunger_drain)
	if hunger_int < 1:
		die()
	

func get_direction():
	if is_on_floor() or is_on_wall():
		has_jump = true
		
	var y_dir = 0;
	
	if Input.is_action_just_pressed("jump" + action_suffix):
		if is_on_floor():
			y_dir = -1
			animated_sprite.play("jump")
		elif has_jump:
			y_dir = -1
			has_jump = false
			animated_sprite.play("jump")
			
	
	if Input.is_action_just_pressed("fastfall" + action_suffix) and not is_on_floor():
		y_dir = 1
			
		
	return Vector2(
		Input.get_action_strength("move_right" + action_suffix) - Input.get_action_strength("move_left" + action_suffix),
		y_dir
	)
	
#	calc 


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


func get_new_animation():
	var animation_new = ""
	
	if consuming:
		if animated_sprite.get_frame() < 5:
			animation_new = "consume"
		else:
			consuming = false
		
	elif is_on_floor():
		if abs(_velocity.x) > 0.1:
			animation_new = "walking"
		else:
			animation_new = "idle"
	else:
		if abs(_velocity.x) > 400:
			animation_new = "walking"
		
		elif _velocity.y > 0:
			animation_new = "falling"
		else:
			animation_new = "jumping"
	
	
		
	return animation_new

func take_damage(damage: int) -> void:
	if hunger_int - damage <= 0:
		die()
	else: hunger_int -= damage

func _on_Hunger_timeout() -> void:
	hunger_int -= 1

func die() -> void:
	hunger_timer.stop()
	print("You died")
	CurrRunData.set_is_dead(true)
	game_over.get_tree().change_scene_to(game_over.next_scene)
	


