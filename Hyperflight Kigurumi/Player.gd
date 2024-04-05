extends CharacterBody2D

# General
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var moveMode = "Glide" # and "Dash", "Launch", "Hyper"
var uiDirection

# Glide
const ACCEL_X = 500
const AIR_RESIST_COEF = 200
const AERODYNAMIC_COEF = 1000
const TERMINAL_X = 300
const TERMINAL_Y = 300
const RESISTANT_TERMINAL_Y = 150
const AERO_TERMINAL_Y = 600

# Flight
const DASH_SPEED = 800
const LAUNCH_SPEED = 1200
const HYPER_SPEED = 2500
const DASH_END_SPEED = 100
const LAUNCH_END_SPEED = 300
const HYPER_END_SPEED = 700
const DASH_DURATION = 0.2
const LAUNCH_DURATION = 1
const STEER_STRENGTH = 2
const FLIGHT_END_LIFT = -100
var launchDir
var dashCooldown = false

func _ready():
	$DashDuration.wait_time = DASH_DURATION
	$LaunchDuration.wait_time = LAUNCH_DURATION

func _physics_process(delta):
	
# TEST block
	#print(velocity)
	#dashCooldown = false
	
# GENERAL
	# Get input direction for later use.
	uiDirection = Input.get_vector("move_left","move_right","move_up","move_down")
	
	# Set rotation of character for non-spinning animations
	if moveMode == "Hyper" or moveMode == "Dash":
		rotation = velocity.angle()
	
	# Flip character based on direction for all animations
	if velocity.x < 0:
		$AnimatedSprite2D.flip_v = true
	elif velocity.x > 0:
		$AnimatedSprite2D.flip_v = false
	
	#updateTrajectoryLaserStatus()
	
# DASH
	if Input.is_action_just_pressed("ui_airdash") and not dashCooldown:
		# Begin dashing in uiDirection
		set_moveMode("Dash")
		#updateTrajectoryLaserStatus()
		dashCooldown = true
		stopTimers()
		$DashDuration.start() 
		launchDir = uiDirection
		velocity = launchDir * DASH_SPEED
	
	# Steer a particular way while Launching
	if moveMode == "Launch":
		steer(delta)
	
	# Dash can be canceled
	if Input.is_action_just_released("ui_airdash"):
		if moveMode == "Dash":
			_on_dash_duration_timeout()
			stopTimers()

# HYPER
	if Input.is_action_just_pressed("ui_hyper") and moveMode == "Launch":
		stopTimers()
		$"../HyperRemnant".start()
		set_moveMode("Hyper")
		velocity = velocity.normalized() * HYPER_SPEED

# GLIDE
	if moveMode == "Glide":
		
	# Y MOVEMENT
		# Gravity. If above or below Terminal_Y velocity, trend towards Terminal_Y velocity.
		if velocity.y < TERMINAL_Y:
			velocity.y += gravity * delta
		if velocity.y > TERMINAL_Y:
			velocity.y -= gravity * delta

		# Add/remove air resistance based on player input. Apply custom terminal velocities.
		if uiDirection.y < 0:
			velocity.y += uiDirection.y * delta * AIR_RESIST_COEF
			velocity.y = clamp(velocity.y,-1000000,RESISTANT_TERMINAL_Y)
			
		if uiDirection.y > 0:
			velocity.y += uiDirection.y * delta * AERODYNAMIC_COEF
			velocity.y = clamp(velocity.y,0,AERO_TERMINAL_Y)
	
	# X MOVEMENT
	
		# Increased acceleration if trying to change uiDirection
		if (uiDirection.x < 0 and velocity.x > 0) or (uiDirection.x > 0 and velocity.x < 0):
			velocity.x += uiDirection.x * ACCEL_X * delta * 3
	
		# Normal acceleration. Trend towards terminal X velocity
		elif uiDirection:
			if abs(velocity.x) < TERMINAL_X:
				velocity.x += uiDirection.x * ACCEL_X * delta
				
			if abs(velocity.x) > TERMINAL_X:
				velocity.x -= uiDirection.x * ACCEL_X * delta
		
		# Slowly lose momentum if not attempting to move
		else:
			velocity.x *= .98 * delta
	
# COLLISION (including Launch)
	
	# Move. Upon collision, store data.
	var collision = move_and_collide(velocity * delta)
	if collision:
		
		var parent = collision.get_collider().get_parent().name

		# Reset dash any time you collide
		dashCooldown = false
		stopTimers()
		
		# Pinball bounce ("Launch")
		if parent == "Pinballs":
			set_moveMode("Launch")
			$LaunchDuration.start()
			launchDir = collision.get_normal()
			velocity = launchDir * LAUNCH_SPEED
				
		# Wall bounce
		if parent == "Walls":
			# Teleport player to origin if they hit the floor, else bounce
			if collision.get_collider().name == "Floor":
				position = Vector2(1200,240)
				velocity = Vector2(0,0)
				set_moveMode("Glide")
			else:
				# Set bounce vector (ignore speed for now)
				velocity = velocity.bounce(collision.get_normal())
				
				# Set bounce speed based on moveMode
				match moveMode:
					"Dash":  velocity = velocity.normalized() * LAUNCH_END_SPEED
					"Launch": velocity = velocity.normalized() * LAUNCH_END_SPEED
					"Hyper":  velocity = velocity.normalized() * HYPER_END_SPEED
				set_moveMode("Glide")

		# bat collision
		if parent == "Bats":
			# Bounce off bat regardless of moveMode
			velocity = velocity.bounce(collision.get_normal()).normalized() * 300
			
			# Kill if Hyper
			if moveMode == "Hyper":
				collision.get_collider().free()
			else:
				pass #WIP DAMAGE PLAYER
			set_moveMode("Glide")
	
func _process(_delta):
	
	#$AimLaser.rotation = velocity.angle()
	
	# Return to Title Screen
	if Input.is_action_just_pressed("ui_menu"):
		get_tree().change_scene_to_file("res://Scenes/title.tscn")

func _on_dash_duration_timeout():
	stopFlight(DASH_END_SPEED)

func _on_launch_duration_timeout():
	stopFlight(LAUNCH_END_SPEED)

#func updateTrajectoryLaserStatus():
	#if moveMode == "Launch":
		#$AimLaser.visible = true
	#else:
		#$AimLaser.visible = false
		
func steer(delta):
	# flight Steering
	launchDir = velocity.normalized() # Current launch direction which will be fought against by player steering
	
	# Influence current direction by player's steering. Normalize again, and re-apply speed.
	velocity = (launchDir + (uiDirection * STEER_STRENGTH * delta)).normalized() * velocity.length()
			
func stopFlight(end_speed: int):
	set_moveMode("Glide")
	velocity = velocity.limit_length(end_speed)
	velocity.y += FLIGHT_END_LIFT
	stopTimers()
	
func stopTimers():
	for node in get_children():
		if node.get_class() == "Timer":
			node.stop()
	$"../HyperRemnant".stop()

func set_moveMode(mode: String):
	moveMode = mode
	$AnimatedSprite2D.animation = mode
