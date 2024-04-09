extends Label

var time = 0
var map_clear = false

onready var enemies = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_node("Enemy_Position").get_child_count()

func _process(delta):
	if map_clear == false:
		time += delta
		var mils = fmod(time, 1)*10
		var secs = fmod(time, 60)
		var mins = fmod(time, 60*60) / 60
		
		var time_passed = "%02d : %02d : %02d" % [mins, secs, mils]
		text = time_passed


func _on_EnemyChecker_body_exited(body):
	if "Skeleton" in body.name || "Wizard" in body.name:
		enemies -= 1
		if enemies == 0:
			map_clear = true
