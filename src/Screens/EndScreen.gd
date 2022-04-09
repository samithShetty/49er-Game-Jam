extends Control

var deathHeading: = "YOU WERE SUPERNATURALLY SELECTED."
var winHeading: = "YOU ARE VICTORIOUS."

func _ready() -> void:
	if CurrRunData.get_is_dead() == false:
		get_node("Label").text = winHeading
	else: get_node("Label").text = deathHeading
