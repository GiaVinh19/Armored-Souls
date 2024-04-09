extends Area2D
const SPEED = 800
var DIRECTION = 1
var RAND = 0
var MOTION = Vector2()

func set_arrow_direction(Direct):
	DIRECTION = Direct
	if Direct == -1:
		$AnimatedSprite.flip_v = true # flip_v because the sprite got rotated -90

func _physics_process(delta):
	MOTION.x = SPEED * delta * DIRECTION # multiply by delta to make the object follows by frame rate since nothing is controlling it
	translate(MOTION)
	$AnimatedSprite.play("Flying")

func _on_VisibilityNotifier2D_screen_exited(): # method that removes the object once it exists outside the screen
	queue_free() # deletes Arrow and its children nodes when it's outside the screen

func _on_Arrow_body_entered(body): # method to detect enemy and trigger a function from the enemy
	if "Skeleton" in body.name || "Wizard" in body.name:
		body.hurt(30)
		body.mini_stun()
		RAND = randi()%3+1
		match RAND:
			1:
				$Sound/Target_01.play()
			2:
				$Sound/Target_02.play()
			3:
				$Sound/Target_03.play()
	else:
		queue_free()

#func _on_After_Image_Timer_timeout():
#		var AFTER_IMAGE = preload("res://Player/After_Image/After_Image.tscn").instance() # make copy of after image object
#		get_parent().add_child(AFTER_IMAGE) # give after image a parent
#		AFTER_IMAGE.position = position
#		AFTER_IMAGE.texture = $AnimatedSprite.frames.get_frame($AnimatedSprite.animation, $AnimatedSprite.frame)
#		AFTER_IMAGE.flip_h = $AnimatedSprite.flip_h
#		AFTER_IMAGE.scale = self.scale
