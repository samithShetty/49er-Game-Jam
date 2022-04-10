class_name ShadowKnight
extends Actor


enum State {
	WALKING,
	DEAD,
	ATTACKING
}

var _state = State.WALKING
export var attack_frame: = false
var damage_dealt: = 3
var upgrade_count: = Vector2(1,0)
var animation = ""

onready var platform_detector = $PlatformDetector
onready var floor_detector_left = $FloorDetectorLeft
onready var floor_detector_right = $FloorDetectorRight
onready var sight_line = $PlayerTargetZone
onready var sprite = $Sprite
onready var attack_box = $AttackZone
onready var animation_player = $AnimationPlayer
onready var player_node = get_node("/root/Game/Level/Player")

# This function is called when the scene enters the scene tree.
# We can initialize variables here.
func _ready():
	
	sight_line.connect("body_entered", self, "_on_PlayerTargetZone_body_entered")
	sight_line.connect("body_exited", self, "_on_PlayerTargetZone_body_exited")
	# disables movement inhibition until enemy is out of the camera for the first time
	set_physics_process(false)
	_velocity.x = speed.x

# Physics process is a built-in loop in Godot.
# If you define _physics_process on a node, Godot will call it every frame.

# At a glance, you can see that the physics process loop:
# 1. Calculates the move velocity.
# 2. Moves the character.
# 3. Updates the sprite direction.
# 4. Updates the animation.
func _on_PlayerTargetZone_body_entered(body: PhysicsBody2D) -> void:
	print("In Sightline")
	#if body.get_collision_layer() == 1:
	if _state != State.DEAD:
		_state = State.ATTACKING

func _on_PlayerTargetZone_body_exited(body: PhysicsBody2D) -> void:
	print("Left Sightline")
	
	if _state == State.ATTACKING:
		_state = State.WALKING

# Splitting the physics process logic into functions not only makes it
# easier to read, it help to change or improve the code later on:
# - If you need to change a calculation, you can use Go To -> Function
#   (Ctrl Alt F) to quickly jump to the corresponding function.
# - If you split the character into a state machine or more advanced pattern,
#   you can easily move individual functions.
func _physics_process(_delta):
	# If the enemy encounters a wall or an edge, the horizontal velocity is flipped.
	if _state == State.WALKING:
		if not floor_detector_left.is_colliding():
			_velocity.x = speed.x
		elif not floor_detector_right.is_colliding():
			_velocity.x = -speed.x

		if is_on_wall():
			_velocity.x *= -1

		# We only update the y value of _velocity as we want to handle the horizontal movement ourselves.
		_velocity.y = move_and_slide(_velocity, FLOOR_NORMAL).y

		# We flip the Sprite depending on which way the enemy is moving. and body_entered.get_global_position().x < self.get_global_position().x
	if _velocity.x > 0 or (_state == State.ATTACKING and (player_node.global_position.x > self.global_position.x)):
		sprite.scale.x = 1
		attack_box.scale.x = 1
	elif _velocity.x < 0 or (_state == State.ATTACKING and (player_node.global_position.x < self.global_position.x)):
		sprite.scale.x = -1
		attack_box.scale.x = -1
	print(_state)
	print(player_node.global_position.x)
	print(self.global_position.x)
	#print(self.global_position.x)
	
	player_node.Hunger.start(player_node.Hunger.get_time_left() - damage_dealt if attack_frame else 0)
	
	if animation != "destroy":
		animation = get_new_animation()

	if animation != animation_player.current_animation:
		animation_player.play(animation)
	
func destroy():
	_state = State.DEAD
	_velocity = Vector2.ZERO

func get_new_animation():
	var animation_new = ""
	if _state == State.DEAD:
		animation_new = "destroy"
		if upgrade_count.y != player_node.upgrade_progress.y:
			player_node.upgrade_progress.y = upgrade_count.y
			player_node.upgrade_progress.x = 0
		player_node.upgrade_progress.x += player_node.upgrade_progress.y

	elif _state == State.ATTACKING:
		animation_new = "attack"
	else:
		if _velocity.x == 0:
			animation_new = "idle"
		else:
			animation_new = "walk"
	return animation_new
