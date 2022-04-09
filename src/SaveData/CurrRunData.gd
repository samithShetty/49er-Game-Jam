extends Node

signal score_updated
signal player_died

var curr_run_time: = 0 setget set_curr_run_time
var all_upgrades: = []
var upgrades_value: = 0 setget set_upgrades_value
var is_dead: = false setget set_is_dead, get_is_dead
var score: = 0 setget set_score

func reset() -> void:
	var curr_run_time = 0
	var all_upgrades = []
	upgrades_value = 0
	is_dead = false
	score = 0
	
func append_upgrade(upgrade_id: int) -> void:
	all_upgrades.append(upgrade_id)
	emit_signal("all_upgrades_updated")
	return

func get_run_upgrades() -> Array:
	return all_upgrades

func set_curr_run_time(value: int) -> void:
	curr_run_time = value
	emit_signal("curr_run_time_updated")
	return

func set_upgrades_value(value: int) -> void:
	upgrades_value = value
	emit_signal("upgrades_value_updated")
	return

func set_score(value: int) -> void:
	score = value
	emit_signal("score_updated")
	return
	
func set_is_dead(state: bool) -> void:
	is_dead = state
	emit_signal("player_died")
	return

func get_is_dead() -> bool:
	return is_dead
	
# score calc later:
# major penalty for player_died signal set to true
# greater score for less time (-log curve?)
# increased score for each upgrade (doesn't cancel out time penalty)
