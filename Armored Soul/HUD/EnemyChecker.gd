extends Area2D

onready var enemies = get_parent().get_node("Enemy_Position").get_child_count()

func _on_EnemyChecker_body_exited(body):
	if "Skeleton" in body.name || "Wizard" in body.name:
		print("died")
		enemies -= 1
		if enemies == 0:
			print("clear")
