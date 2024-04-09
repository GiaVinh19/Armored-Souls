extends Enemy

func _ready():
	HP = 150
	MAX_SPEED = 100
	DAMAGE = 25
	$"Status/HP".max_value = HP
	$"Status/HP".value = HP
	PRE_ATTACK_FRAME = 0.538
