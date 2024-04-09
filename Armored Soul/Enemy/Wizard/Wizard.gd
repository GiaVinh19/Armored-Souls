extends Enemy

const BOLT = preload("res://Enemy/Wizard/Bolt.tscn") 

func _ready():
	HP = 100
	MAX_SPEED = 150
	DAMAGE = 40
	$"Status/HP".max_value = HP
	$"Status/HP".value = HP
	PRE_ATTACK_FRAME = 0.625

func attack():
	if !IS_FROZEN:
		IS_ATTACKING = true
		$AnimatedSprite.play("Attack")
		yield(get_tree().create_timer(PRE_ATTACK_FRAME),"timeout")
		if IS_ATTACKING:
			$Sound/Swing.play()
			$Hitscan/Hitscan_Collision.disabled = false
			yield(get_tree().create_timer(ATTACK_FRAME),"timeout")
			$Hitscan/Hitscan_Collision.disabled = true
			var Bolt = BOLT.instance()
			if !$AnimatedSprite.flip_h:
				if sign($Bolt_Spawn.position.x) == -1:
					$Bolt_Spawn.position.x *= -1
				if sign($Bolt_Spawn.position.x) == 1:
					Bolt.set_bolt_direction(1)
			elif $AnimatedSprite.flip_h:
				if sign($Bolt_Spawn.position.x) == 1:
					$Bolt_Spawn.position.x *= -1
				if sign($Bolt_Spawn.position.x) == -1:
					Bolt.set_bolt_direction(-1)
			get_parent().add_child(Bolt)
			$Bolt_Spawn.position.y = -4
			Bolt.position = $Bolt_Spawn.global_position
			
