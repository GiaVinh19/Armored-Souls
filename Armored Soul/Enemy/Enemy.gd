extends KinematicBody2D
class_name Enemy

# PHYSICS 
var MOTION = Vector2()
var UP = Vector2(0,-1)

#VELOCITY and GRAVITY
const GRAVITY = 35.0
const ACCEL = 25.0
const MAX_GRAVITY = 1000

var MAX_SPEED = 0.0

const JUMP = -800

var DIRECTION = 1
var RAND = 0
var COUNTER = 0

#ATTACK
var IS_ATTACKING = false
const ATTACK_FRAME = 0.033
var PRE_ATTACK_FRAME = 0
var DAMAGE = 0

# STATUS
var HP = 0
var IS_DEAD = false
var IS_MINI_STUN = false
var IS_FROZEN = false

func _ready():
	pass

func mini_stun():
	if !IS_FROZEN:
		IS_ATTACKING = false
		IS_MINI_STUN = false
		yield(get_tree().create_timer(1.0/60),"timeout")
		IS_MINI_STUN = true
		if HP > 0:
			$AnimatedSprite.play("Mini_Stun")

func counter():
	if !IS_FROZEN:
		COUNTER += 1
		$Status/Counter.set_text(String(COUNTER))
	if COUNTER == 10:
		$Status/Counter.set_text("")
		call("freeze")
		COUNTER = 0

func freeze():
	IS_ATTACKING = false
	IS_MINI_STUN = false
	IS_FROZEN = true
	$CollisionShape2D_Freeze.set_deferred("disabled", false)
	if !IS_DEAD:
		$AnimatedSprite.play("Freeze")
		$Sound/Freeze.play()

func hurt(damage):
	HP = HP - damage
	$Status/HP.value = HP
	if HP <= 0:
		call("dead")

func dead():
	IS_ATTACKING = false
	IS_MINI_STUN = false
	IS_FROZEN = false
	IS_DEAD = true
	MOTION = Vector2(0,0)
	$AnimatedSprite.play("Dead")
	$CollisionShape2D_Freeze.set_deferred("disabled", true)
	$CollisionShape2D_Head.set_deferred("disabled", true)
	$CollisionShape2D_Body.set_deferred("disabled", true)
	$Status/Counter.visible = false
	$Status/HP.visible = false

# warning-ignore:unused_argument
func _physics_process(delta):
	MOTION.y += GRAVITY
	MOTION.y = min(MOTION.y, MAX_GRAVITY)

	if !IS_FROZEN:
		$CollisionShape2D_Freeze.set_deferred("disabled", true)

	if  !IS_FROZEN && !IS_DEAD && !IS_MINI_STUN && !IS_ATTACKING:
		MOTION.x = MAX_SPEED * DIRECTION

		if DIRECTION == -1: 
			$AnimatedSprite.play("Walk")
			$AnimatedSprite.flip_h = true
		elif DIRECTION == 1:
			$AnimatedSprite.play("Walk")
			$AnimatedSprite.flip_h = false

		if !$AnimatedSprite.flip_h:
			$Detect_Player.scale.x = 1
			$Detect_Player2.scale.x = -1
			$Hitscan.scale.x = 1
		elif $AnimatedSprite.flip_h:
			$Detect_Player.scale.x = -1
			$Detect_Player2.scale.x = 1
			$Hitscan.scale.x = -1

		MOTION = move_and_slide(MOTION, UP)

		if is_on_wall():
			DIRECTION = DIRECTION * -1
			$RayCast2D.position.x *= -1
			
		if !$RayCast2D.is_colliding():
			DIRECTION = DIRECTION * -1
			$RayCast2D.position.x *= -1

#		if get_slide_count() > 0:
#			for i in range(get_slide_count()):
#				if "Player" in get_slide_collision(i).collider.name:
#					get_slide_collision(i).collider.dead()
############
# FUNCTION #
############

func _on_AnimatedSprite_animation_finished():
	IS_MINI_STUN = false # Replace with function body.
	IS_ATTACKING = false
	IS_FROZEN = false

func attack():
	if !IS_FROZEN:
		IS_ATTACKING = true
		$AnimatedSprite.play("Attack")
		$Sound/Swing.play()
		yield(get_tree().create_timer(PRE_ATTACK_FRAME),"timeout")
		if IS_ATTACKING:
			$Hitscan/Hitscan_Collision.disabled = false
			yield(get_tree().create_timer(ATTACK_FRAME),"timeout")
			$Hitscan/Hitscan_Collision.disabled = true

func _on_attack_body_entered(body):
	if "Player" in body.name:
		body.hurt(DAMAGE)
		body.knock()
		RAND = randi()%3+1
		match RAND:
			1:
				$Sound/Hit_01.play()
			2:
				$Sound/Hit_02.play()
			3:
				$Sound/Hit_03.play()

func _on_Detect_Player_body_entered(body):
	if "Player" in body.name && !IS_DEAD && !IS_MINI_STUN && !IS_ATTACKING:
		call_deferred("attack")

func _on_Detect_Player2_body_entered(body):
	if "Player" in body.name && !IS_DEAD && !IS_MINI_STUN && !IS_ATTACKING:
		DIRECTION = DIRECTION * -1
		$RayCast2D.position.x *= -1
		call_deferred("attack")
