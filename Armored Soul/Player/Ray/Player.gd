extends KinematicBody2D

# PHYSICS 
var MOTION = Vector2()

const UP = Vector2(0,-1)

#VELOCITY and GRAVITY
const GRAVITY = 20.0

const ACCEL = 75.0

const ATTACK_SPEED = 1000.0

const MAX_GRAVITY = 950.0

const SWORD_GRAVITY = 250.0

const SWORD_MAX_GRAVITY = 2000.0

const MAX_SPEED = 500.0

const JUMP = -800.0

const DASH = 1000.0

const ARROW = preload("res://Player/Arrow/Arrow.tscn") # add Arrow.tscn as part of player's script

var ON_GROUND = false

#STAT
var HP = 100
var COUNTER = 0
var RAND = 0

#ATTACK & WEAPON
var MELEE_ATTACK_COUNT = 0
var WEAPON = 0
var ATTACK_FRAME = 0.033

#COOLDOWN
var BOW_ON_COOLDOWN = false
var AIR_ON_COOLDOWN = false #delay for air attacks
var DASH_ON_COOLDOWN = false
var COMBO_DELAY = false #delay for sword combo
# AIR_LIMIT
const AIR_DASH_LIMIT = 1
var AIR_DASH_COUNT = 0

const AIR_JUMP_LIMIT = 1
var AIR_JUMP_COUNT = 0

const AIR_BOW_LIMIT = 1
var AIR_BOW_COUNT = 0

#DASH_LIMIT
const DASH_LIMIT = 3
var DASH_COUNT = 0

#ANIMATION:
var IS_DASHING = false

var IS_BOW_ATTACKING = false

var IS_MELEE_ATTACKING = false

var IS_KICK_FALLING = false

var IS_SWORD_FALLING = false

var IS_SWORD_FALL_FINISH = false

# STATUS
var IS_DEAD = false
var IS_HURT = false
var IS_KNOCKED = false
var IS_IGNITED = false

func _ready():
	pass

# warning-ignore:unused_argument

func _process(delta):

	if !IS_DEAD:
		var FRICTION = false # friction is false when player is doing something

###########
# GRAVITY #
###########

		if !IS_KNOCKED: #reset the HIT collision mask when stand back up
			self.set_collision_mask_bit(3, true)

		if !IS_BOW_ATTACKING && !IS_MELEE_ATTACKING && !IS_DASHING && !IS_KICK_FALLING && !IS_SWORD_FALLING && !IS_SWORD_FALL_FINISH:
			MOTION.y += GRAVITY # build up gravity to fall faster
			MOTION.y = min(MOTION.y, MAX_GRAVITY) # if GRAVITY reaches equal to or greater than MAX_GRAVITY, will limit to MAX_GRAVITY

		elif IS_BOW_ATTACKING || IS_MELEE_ATTACKING:
			MOTION.y = lerp(MOTION.y, GRAVITY/3, 0.75) # gravity is weaker when attacking

		elif IS_DASHING: #stop playing falling animtion
			MOTION.y = 0.275

		elif IS_SWORD_FALL_FINISH:
			MOTION.y = 1

		elif IS_KICK_FALLING:
			$AnimatedSprite.play("Kick_Falling")
			if !$AnimatedSprite.flip_h:
				MOTION.x = ATTACK_SPEED
			elif $AnimatedSprite.flip_h:
				MOTION.x = -ATTACK_SPEED
			MOTION.y = ATTACK_SPEED
			if is_on_floor():
				IS_KICK_FALLING = false
				$Sound/Fissure.play()
				$Melee/Kick_Fall/Kick_Fall_Collision.disabled = true

		elif IS_SWORD_FALLING:
			$AnimatedSprite.play("Sword_Falling")
			MOTION.y += SWORD_GRAVITY
			MOTION.y = min(MOTION.y , SWORD_MAX_GRAVITY)
			if is_on_floor():
				IS_SWORD_FALLING = false
				$Sound/Fissure.play()
				$Melee/Sword_Fall/Sword_Fall_Collision.disabled = true
				call("sword_fall_finish")

##################
# ON_FLOOR RESET #
##################

		if is_on_floor():
			if !ON_GROUND:
				MELEE_ATTACK_COUNT = 0
#				IS_BOW_ATTACKING = false
			ON_GROUND = true
			AIR_BOW_COUNT = 0
			AIR_JUMP_COUNT = 0
			AIR_DASH_COUNT = 0

		if !$AnimatedSprite.flip_h:
			$Melee.scale.x = 1
		if $AnimatedSprite.flip_h:
			$Melee.scale.x = -1

#########
# INPUT #
#########

		if Input.is_action_pressed("ui_right") && !Input.is_action_pressed("ui_left") && !IS_KNOCKED && !IS_BOW_ATTACKING && !IS_MELEE_ATTACKING && !IS_DASHING && !IS_KICK_FALLING && !IS_SWORD_FALLING && !IS_SWORD_FALL_FINISH : # when press right
			move_right()

		elif Input.is_action_pressed("ui_left") && !Input.is_action_pressed("ui_right") && !IS_KNOCKED && !IS_BOW_ATTACKING && !IS_MELEE_ATTACKING && !IS_DASHING && !IS_KICK_FALLING && !IS_SWORD_FALLING && !IS_SWORD_FALL_FINISH: # when press left
			move_left()

		else: # no input
			FRICTION = true

		if FRICTION && !IS_DASHING: # if idle
			if is_on_floor():
				MOTION.x = lerp(MOTION.x, 0, 0.3) # take the current x speed, reaches to 0 speed, with the input percentage
			elif !is_on_floor():
				MOTION.x = lerp(MOTION.x, 0, 0.15)

		if Input.is_action_just_pressed("ui_select"): # space
			jump()

		if Input.is_action_just_released("ui_select"): # if release while player is going up, player will fall
			release_jump()

		if Input.is_action_just_pressed("ui_Q"):
			weapon_switch()

		if Input.is_action_just_pressed("ui_Shift"):
			dash()

		if Input.is_action_just_pressed("ui_D"):
			create_arrow()
	
		if Input.is_action_just_pressed("ui_A") && !COMBO_DELAY: # Melee Attack 1
			if WEAPON == 0:
				sword_attack()
			elif WEAPON == 1:
				fist_attack()

		if Input.is_action_pressed("ui_down"): # combo activator 
			$Timer_Node/Combo_Delay.start()
			COMBO_DELAY = true
	
		if Input.is_action_just_pressed("ui_A") && COMBO_DELAY: #Directional Melee Attack 1
			if WEAPON == 0:
				sword_attack_down()
			elif WEAPON == 1:
				fist_attack()

		if Input.is_action_just_pressed("ui_S"): # Melee Attack 2
			if WEAPON == 0:
				pass
			if WEAPON == 1:
				kick_attack()

		if Input.is_action_just_pressed("ui_escape"):
			return get_tree().change_scene("res://Title/Title_Screen.tscn")

###################
# ANIMATED_SPRITE #
###################

		if ON_GROUND && FRICTION && is_on_floor() && !IS_BOW_ATTACKING && !IS_MELEE_ATTACKING && !IS_DASHING && !IS_KNOCKED && !IS_SWORD_FALL_FINISH: 
			if WEAPON == 0:
				$AnimatedSprite.play("Idle_Sword")
			if WEAPON == 1:
				$AnimatedSprite.play("Idle_Fist")

		if !is_on_floor() && !IS_BOW_ATTACKING && !IS_MELEE_ATTACKING && !IS_DASHING && !IS_KNOCKED && !IS_KICK_FALLING && !IS_SWORD_FALLING && !IS_SWORD_FALL_FINISH:
			if MOTION.y >= 0:
				$AnimatedSprite.play("Fall")
			elif MOTION.y < 0 && AIR_JUMP_COUNT == 0:
				if WEAPON == 0:
					$AnimatedSprite.play("Jump_Sword")
				if WEAPON == 1:
					$AnimatedSprite.play("Jump_Fist")
			elif MOTION.y < 0 && AIR_JUMP_COUNT == 1:
				if WEAPON == 0:
					$AnimatedSprite.play("Air_Jump_Sword")
				if WEAPON == 1:
					$AnimatedSprite.play("Air_Jump_Fist")

#		if is_on_floor(): # Animation cancel
#			if !ON_GROUND: # when player just landed
#				pass
#			ON_GROUND = true  

#####################
# COLLISION_PHYSICS #
#####################

		MOTION = move_and_slide(MOTION, UP) # make MOTION a platformer physics, the up variable make the platform pushes the player up just like Newton's law
		pass

#		if get_slide_count() > 0:
#			for i in range(get_slide_count()):
#				if "Skeleton" in get_slide_collision(i).collider.name:
#					dead()

############
# FUNCTION #
############

# WEAPON SWITCH #
func weapon_switch():
	MELEE_ATTACK_COUNT = 0
	if WEAPON == 0:
		WEAPON = 1
	elif WEAPON == 1:
		WEAPON = 0

# ATTACK #

func sword_attack():

	if !IS_BOW_ATTACKING && !IS_MELEE_ATTACKING && !IS_DASHING && !IS_KNOCKED && !IS_SWORD_FALL_FINISH:

		if is_on_floor(): # ON_FLOOR ATTACK #
			if MELEE_ATTACK_COUNT == 0:
				IS_MELEE_ATTACKING = true
				$AnimatedSprite.play("Sword_Attack_01")
				$Sound/Sword_01.play()
				if !$AnimatedSprite.flip_h:
					MOTION.x = MAX_SPEED
				elif $AnimatedSprite.flip_h:
					MOTION.x = -MAX_SPEED
				yield(get_tree().create_timer(2.0/20),"timeout")
				if IS_MELEE_ATTACKING:
					$Melee/Sword_Normal/Sword_Collision_01.disabled = false
					yield(get_tree().create_timer(ATTACK_FRAME),"timeout")
					$Melee/Sword_Normal/Sword_Collision_01.disabled = true
					MELEE_ATTACK_COUNT = 1
					$Timer_Node/Melee_Timer.start()

			elif MELEE_ATTACK_COUNT == 1:
				IS_MELEE_ATTACKING = true
				$AnimatedSprite.play("Sword_Attack_02")
				$Sound/Sword_02.play()
				if !$AnimatedSprite.flip_h:
					MOTION.x = MAX_SPEED
				elif $AnimatedSprite.flip_h:
					MOTION.x = -MAX_SPEED
				yield(get_tree().create_timer(2.0/20),"timeout")
				if IS_MELEE_ATTACKING:
					$Melee/Sword_Normal/Sword_Collision_02.disabled = false
					yield(get_tree().create_timer(ATTACK_FRAME),"timeout")
					$Melee/Sword_Normal/Sword_Collision_02.disabled = true
					MELEE_ATTACK_COUNT = 2
					$Timer_Node/Melee_Timer.start()

			elif MELEE_ATTACK_COUNT == 2:
				IS_MELEE_ATTACKING = true
				$AnimatedSprite.play("Sword_Attack_03")
				$Sound/Sword_03.play()
				if !$AnimatedSprite.flip_h:
					MOTION.x = MAX_SPEED*3
				elif $AnimatedSprite.flip_h:
					MOTION.x = -MAX_SPEED*3
				yield(get_tree().create_timer(3.0/25),"timeout")
				if IS_MELEE_ATTACKING:
					$Melee/Sword_Finish/Sword_Collision_03.disabled = false
					yield(get_tree().create_timer(ATTACK_FRAME),"timeout")
					$Melee/Sword_Finish/Sword_Collision_03.disabled = true
					MELEE_ATTACK_COUNT = 0

		elif !is_on_floor() && !AIR_ON_COOLDOWN: # ON_AIR ATTACK #

			if MELEE_ATTACK_COUNT == 0:
				IS_MELEE_ATTACKING = true
				$AnimatedSprite.play("Air_Sword_Attack_01")
				$Sound/Sword_01.play()
				yield(get_tree().create_timer(1.0/20),"timeout")
				if IS_MELEE_ATTACKING:
					$Melee/Sword_Normal/Air_Sword_Collision_01.disabled = false
					yield(get_tree().create_timer(ATTACK_FRAME),"timeout")
					$Melee/Sword_Normal/Air_Sword_Collision_01.disabled = true
					$Timer_Node/Melee_Timer.start()
					MELEE_ATTACK_COUNT = 1

			elif MELEE_ATTACK_COUNT == 1:
				IS_MELEE_ATTACKING = true
				$AnimatedSprite.play("Air_Sword_Attack_02")
				$Sound/Sword_02.play()
				yield(get_tree().create_timer(1.0/20),"timeout")
				if IS_MELEE_ATTACKING:
					$Melee/Sword_Finish/Air_Sword_Collision_02.disabled = false
					yield(get_tree().create_timer(ATTACK_FRAME),"timeout")
					$Melee/Sword_Finish/Air_Sword_Collision_02.disabled = true
					MELEE_ATTACK_COUNT = 0
					AIR_ON_COOLDOWN = true
					$Timer_Node/Air_Coolddown.start()

func sword_attack_down():
	if !is_on_floor() && !IS_BOW_ATTACKING && !IS_MELEE_ATTACKING && !IS_DASHING && !IS_KNOCKED && !IS_SWORD_FALLING && !IS_SWORD_FALL_FINISH:
		IS_MELEE_ATTACKING = true
		$AnimatedSprite.play("Sword_Fall")
		yield(get_tree().create_timer(2.0/15),"timeout")
		if IS_MELEE_ATTACKING:
			$Melee/Sword_Fall/Sword_Fall_Collision.disabled = false
			IS_MELEE_ATTACKING = false
			call("sword_falling")

func fist_attack():

	if !IS_BOW_ATTACKING && !IS_MELEE_ATTACKING && !IS_DASHING && !IS_KNOCKED && !IS_SWORD_FALL_FINISH:

		if is_on_floor(): # ON_FLOOR ATTACK #

			if MELEE_ATTACK_COUNT == 0:
				IS_MELEE_ATTACKING = true
				$AnimatedSprite.play("Fist_Attack_01")
				$Sound/Fist_01.play()
				yield(get_tree().create_timer(2.0/30),"timeout")
				if IS_MELEE_ATTACKING:
					$Melee/Fist_Normal/Fist_Collision_01.disabled = false
					yield(get_tree().create_timer(ATTACK_FRAME),"timeout")
					$Melee/Fist_Normal/Fist_Collision_01.disabled = true
					MELEE_ATTACK_COUNT = 1
					$Timer_Node/Melee_Timer.start()

			elif MELEE_ATTACK_COUNT == 1:
				IS_MELEE_ATTACKING = true
				$AnimatedSprite.play("Fist_Attack_02")
				$Sound/Fist_02.play()
				yield(get_tree().create_timer(2.0/30),"timeout")
				if IS_MELEE_ATTACKING:
					$Melee/Fist_Normal/Fist_Collision_02.disabled = false
					yield(get_tree().create_timer(ATTACK_FRAME),"timeout")
					$Melee/Fist_Normal/Fist_Collision_02.disabled = true
					MELEE_ATTACK_COUNT = 0
					$Timer_Node/Melee_Timer.start()

		elif !is_on_floor(): # ON_AIR ATTACK #
			pass

func kick_attack():

	if !IS_BOW_ATTACKING && !IS_MELEE_ATTACKING && !IS_DASHING && !IS_KNOCKED && !IS_SWORD_FALL_FINISH:

		if is_on_floor(): # ON_FLOOR ATTACK #

			if MELEE_ATTACK_COUNT == 0:
				IS_MELEE_ATTACKING = true
				$AnimatedSprite.play("Kick_Attack_01")
				$Sound/Kick_01.play()
				yield(get_tree().create_timer(2.0/15),"timeout")
				if IS_MELEE_ATTACKING:
					$Melee/Kick_Normal/Kick_Collision_01.disabled = false
					yield(get_tree().create_timer(ATTACK_FRAME),"timeout")
					$Melee/Kick_Normal/Kick_Collision_01.disabled = true
					MELEE_ATTACK_COUNT = 1
					$Timer_Node/Melee_Timer.start()

			elif MELEE_ATTACK_COUNT == 1:
				IS_MELEE_ATTACKING = true
				$AnimatedSprite.play("Kick_Attack_02")
				$Sound/Kick_02.play()
				yield(get_tree().create_timer(1.0/15),"timeout")
				if IS_MELEE_ATTACKING:
					$Melee/Kick_Normal/Kick_Collision_02.disabled = false
					yield(get_tree().create_timer(ATTACK_FRAME),"timeout")
					$Melee/Kick_Normal/Kick_Collision_02.disabled = true
					MELEE_ATTACK_COUNT = 0
					$Timer_Node/Melee_Timer.start()

		elif !is_on_floor() && !IS_KICK_FALLING :
			IS_MELEE_ATTACKING = true
			$AnimatedSprite.play("Kick_Fall")
			yield(get_tree().create_timer(2.0/15),"timeout")
			if IS_MELEE_ATTACKING:
				$Melee/Kick_Fall/Kick_Fall_Collision.disabled = false
				IS_MELEE_ATTACKING = false
				call("kick_falling")

func create_arrow():
	if !IS_BOW_ATTACKING && !IS_MELEE_ATTACKING && !IS_DASHING && !IS_KNOCKED && !IS_SWORD_FALL_FINISH:
		if is_on_floor() && !BOW_ON_COOLDOWN:
			IS_BOW_ATTACKING = true
			var Arrow = ARROW.instance()
			$AnimatedSprite.play("Bow_Attack")
			$Sound/Bow_Pull.play()
			yield(get_tree().create_timer(7.0/9),"timeout")
			if IS_BOW_ATTACKING == true:
				$Sound/Bow_Pull.stop()
				$Sound/Bow_Release.play()
				if sign($Arrow_Spawn.position.x) == 1:
					Arrow.set_arrow_direction(1)
					MOTION.x = -MAX_SPEED
				elif sign($Arrow_Spawn.position.x) == -1:
					Arrow.set_arrow_direction(-1)
					MOTION.x = MAX_SPEED
				get_parent().add_child(Arrow)
				$Arrow_Spawn.position.y = 0
				Arrow.position = $Arrow_Spawn.global_position
				BOW_ON_COOLDOWN = true
				$Timer_Node/Bow_Cooldown.start()

		elif !is_on_floor() && AIR_BOW_COUNT < AIR_BOW_LIMIT:
			AIR_BOW_COUNT += 1
			IS_BOW_ATTACKING = true
			var Arrow = ARROW.instance()
			$AnimatedSprite.play("Air_Bow_Attack")
			$Sound/Bow_Pull.play()
			yield(get_tree().create_timer(4.0/9),"timeout")
			if IS_BOW_ATTACKING == true:
				$Sound/Bow_Pull.stop()
				$Sound/Bow_Release.play()
				if sign($Arrow_Spawn.position.x) == 1:
					Arrow.set_arrow_direction(1)
					MOTION.x = -MAX_SPEED/3
				elif sign($Arrow_Spawn.position.x) == -1:
					Arrow.set_arrow_direction(-1)
					MOTION.x = MAX_SPEED/3
				get_parent().add_child(Arrow)
				$Arrow_Spawn.position.y = -2.5
				Arrow.position = $Arrow_Spawn.global_position

# MOVEMENT #

func move_right():
	MOTION.x = min(MOTION.x + ACCEL, MAX_SPEED) # the right velocity will be equal to the current x speed + acceleration when ui_right is hold dow, but limit to MAX_SPEED
	$AnimatedSprite.flip_h = false
	if sign($Arrow_Spawn.position.x) == -1:
		$Arrow_Spawn.position.x *= -1
	if is_on_floor():
		if WEAPON == 0:
			$AnimatedSprite.play("Run_Sword")
		if WEAPON == 1:
			$AnimatedSprite.play("Run_Fist")

func move_left():
	MOTION.x = max(MOTION.x - ACCEL, -MAX_SPEED) # the left velocity will be equal to the current x speed - acceleration when ui_left is hold dow, but limit to -MAX_SPEED
	$AnimatedSprite.flip_h = true # sprite is fliped to the left
	if sign($Arrow_Spawn.position.x) == 1:
		$Arrow_Spawn.position.x *= -1
	if is_on_floor():
		if WEAPON == 0:
			$AnimatedSprite.play("Run_Sword")
		if WEAPON == 1:
			$AnimatedSprite.play("Run_Fist")

func jump():
	RAND = randi()%3+1
	if !IS_BOW_ATTACKING && !IS_MELEE_ATTACKING && !IS_DASHING && !IS_KNOCKED && !IS_SWORD_FALL_FINISH && !IS_SWORD_FALLING:

		if is_on_floor():
			MOTION.y = JUMP
			ON_GROUND = false
			MELEE_ATTACK_COUNT = 0
			match RAND:
				1:
					$Sound/Jump_01.play()
				2:
					$Sound/Jump_02.play()
				3:
					$Sound/Jump_03.play()

		if !is_on_floor() && AIR_JUMP_COUNT < AIR_JUMP_LIMIT:
			MOTION.y = JUMP
			AIR_JUMP_COUNT += 1
			ON_GROUND = false
			MELEE_ATTACK_COUNT = 0
			match RAND:
				1:
					$Sound/Jump_01.play()
				2:
					$Sound/Jump_02.play()
				3:
					$Sound/Jump_03.play()

func release_jump():
	if !is_on_floor() && MOTION.y < 0 && !IS_BOW_ATTACKING && !IS_MELEE_ATTACKING && !IS_DASHING && !IS_KNOCKED && !IS_SWORD_FALL_FINISH:
		MOTION.y = lerp(MOTION.y, 0, 0.75)

func dash():
	if !IS_BOW_ATTACKING && !IS_MELEE_ATTACKING && !IS_DASHING && !IS_KNOCKED && !IS_SWORD_FALL_FINISH && !IS_SWORD_FALL_FINISH:

		if is_on_floor() && !DASH_ON_COOLDOWN && DASH_COUNT < DASH_LIMIT:
			DASH_ON_COOLDOWN = true
			IS_DASHING = true
			DASH_COUNT += 1
			$Timer_Node/Dash_Cooldown.start()
			$Timer_Node/Dash_Delay.start()
			$AnimatedSprite.play("Dash")
			$Sound/Dash.play()
			if !$AnimatedSprite.flip_h:
				MOTION.x = DASH
			elif $AnimatedSprite.flip_h:
				MOTION.x = -DASH

		elif !is_on_floor() && AIR_DASH_COUNT < AIR_DASH_LIMIT:
			IS_DASHING = true
			$AnimatedSprite.play("Dash")
			$Sound/Dash.play()
			AIR_DASH_COUNT += 1
			if !$AnimatedSprite.flip_h:
				MOTION.x = DASH
			elif $AnimatedSprite.flip_h:
				MOTION.x = -DASH

# STATUS #

func ignite():
	IS_IGNITED = true
	$Sound/Ignite.play()
	$Sound/Ignite_Loop.play()
	$Timer_Node/Ignite_Cooldown.start()
	$Ignite.set_text("IGNITED")

func kick_falling():
	IS_KICK_FALLING = true

func sword_falling():
	IS_SWORD_FALLING = true

func sword_fall_finish():
	IS_SWORD_FALL_FINISH = true
	$AnimatedSprite.play("Sword_Fall_Finish")

func counter():
	if !IS_IGNITED:
		COUNTER += 1
		$Counter.set_text(String(COUNTER))
	if COUNTER == 10:
		$Counter.set_text("")
		call("ignite")
		COUNTER = 0

func knock():
	IS_BOW_ATTACKING = false
	IS_MELEE_ATTACKING = false
	IS_DASHING = false
	IS_KICK_FALLING = false
	IS_SWORD_FALLING = false
	IS_KNOCKED = true
	self.set_collision_mask_bit(3, false) #Remove the hit collision mask to be temporarily invulnerable
	if HP > 0:
		$AnimatedSprite.play("Knock")


func hurt(damage):
	HP = HP - damage
	$"UI/Stats bar/Top Left/Text/HP".value = HP
	if HP <= 0:
		call("dead")

func dead():
	IS_BOW_ATTACKING = false
	IS_MELEE_ATTACKING = false
	IS_DASHING = false
	IS_KNOCKED = false
	IS_DEAD = true
	$AnimatedSprite.play("Dead")
	$CollisionShape2D.set_deferred("disabled", true)
	$Timer_Node/Dead_Timer.start()

func _on_Dead_Timer_timeout():
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Title/Title_Screen.tscn")

# ANIMATION_FINISHER #

func _on_AnimatedSprite_animation_finished():
	IS_BOW_ATTACKING = false
	IS_MELEE_ATTACKING = false
	IS_DASHING = false
	IS_KNOCKED = false
	IS_SWORD_FALL_FINISH = false

# DAMAGE #

func _on_Sword_Normal_body_entered(body):
	if "Skeleton" in body.name || "Wizard" in body.name:
		body.hurt(20)
		body.mini_stun()
		if MELEE_ATTACK_COUNT == 0:
			$Sound/Sword_Hit_01.play()
		elif MELEE_ATTACK_COUNT == 1:
			$Sound/Sword_Hit_02.play()

func _on_Sword_Finish_body_entered(body):
	if "Skeleton" in body.name || "Wizard" in body.name:
		body.hurt(40)
		body.mini_stun()
		$Sound/Sword_Hit_03.play()

# MISC #

func _on_After_Image_Timer_timeout():
	if IS_DASHING:
		var AFTER_IMAGE = preload("res://Player/After_Image/After_Image.tscn").instance() # make copy of after image object
		get_parent().add_child(AFTER_IMAGE) # give after image a parent
		AFTER_IMAGE.position = position
		AFTER_IMAGE.texture = $AnimatedSprite.frames.get_frame($AnimatedSprite.animation, $AnimatedSprite.frame)
		AFTER_IMAGE.flip_h = $AnimatedSprite.flip_h
		AFTER_IMAGE.scale = self.scale

# COOL_DOWN #

func _on_Dash_Cooldown_timeout():
	DASH_COUNT = 0

func _on_Dash_Delay_timeout():
	DASH_ON_COOLDOWN = false

func _on_Melee_Timer_timeout():
	MELEE_ATTACK_COUNT = 0

func _on_Fist_Normal_body_entered(body):
	if "Skeleton" in body.name || "Wizard" in body.name:
		body.hurt(5)
		body.counter()
		body.mini_stun()
		if MELEE_ATTACK_COUNT == 0:
			$Sound/Fist_Hit_01.play()
		elif MELEE_ATTACK_COUNT ==1:
			$Sound/Fist_Hit_02.play()

func _on_Kick_Normal_body_entered(body):
	if "Skeleton" in body.name || "Wizard" in body.name:
		body.hurt(10)
		body.mini_stun()
		call("counter")
		if MELEE_ATTACK_COUNT == 0:
			$Sound/Kick_Hit_01.play()
			if IS_IGNITED:
				$Sound/Ignite_Hit_01.play()
		elif MELEE_ATTACK_COUNT ==1:
			$Sound/Kick_Hit_02.play()
			if IS_IGNITED:
				$Sound/Ignite_Hit_02.play()

func _on_Bow_Cooldown_timeout():
	BOW_ON_COOLDOWN = false

func _on_Air_Coolddown_timeout():
	AIR_ON_COOLDOWN = false

func _on_Ignite_Cooldown_timeout():
	IS_IGNITED = false
	$Sound/Ignite_Loop.stop()
	$Ignite.set_text("")

func _on_Kick_Fall_body_entered(body):
	if "Skeleton" in body.name || "Wizard" in body.name:
		body.hurt(30)
		body.mini_stun()
		if IS_IGNITED:
			$Sound/Ignite_Hit_01.play()

func _on_Sword_Fall_body_entered(body):
	if "Skeleton" in body.name || "Wizard" in body.name:
		body.hurt(30)
		body.mini_stun()

func _on_Combo_Delay_timeout():
	COMBO_DELAY = false
