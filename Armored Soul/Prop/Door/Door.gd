extends Area2D

export (String, FILE, "*.tscn") var world

# warning-ignore:unused_argument
func _physics_process(delta):
	var door = get_overlapping_bodies()
	for Player in door:
		if Player.name == "Player":
# warning-ignore:return_value_discarded
			get_tree().change_scene(world)
