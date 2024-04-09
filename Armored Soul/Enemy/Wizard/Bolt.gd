extends Area2D
const SPEED = 800
var DIRECTION = 1
var RAND = 0
var MOTION = Vector2()

func set_bolt_direction(Direct):
	DIRECTION = Direct
	if Direct == -1:
		$AnimatedSprite.flip_v = true # flip_v because the sprite got rotated -90

func _physics_process(delta):
	MOTION.x = SPEED * delta * DIRECTION # multiply by delta to make the object follows by frame rate since nothing is controlling it
	translate(MOTION)
	$AnimatedSprite.play("Flying")

func _on_VisibilityNotifier2D_screen_exited(): # method that removes the object once it exists outside the screen
	queue_free() # deletes Arrow and its children nodes when it's outside the screen

func _on_Bolt_body_entered(body):
	if "Skeleton" in body.name || "Wizard" in body.name:
		body.hurt(10)
		body.mini_stun()
		RAND = randi()%3+1
		match RAND:
			1:
				$Sound/Target_01.play()
			2:
				$Sound/Target_02.play()
	elif "Player" in body.name:
		body.hurt(10)
		body.knock()
		RAND = randi()%2+1
		match RAND:
			1:
				$Sound/Target_01.play()
			2:
				$Sound/Target_02.play()
	else:
		queue_free()
