tool # I don't really know what this does; has something to do with the warning
extends Area2D


onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")


export var next_scene: PackedScene


func _on_Portal2D_body_entered(body: Node) -> void:
	
	# if the body entering is the player's trigger the teleport() function
	if body.get_collision_layer() == 1:
		teleport()


func _get_configuration_warning() -> String:
	return "The next scene property can't be empty" if not next_scene else ""

func teleport() -> void:
	anim_player.play("fade_to_black")
	yield(anim_player, "animation_finished")
	get_tree().change_scene_to(next_scene)
