extends CharacterBody3D

var ray_origin = Vector3()
var ray_target = Vector3()

var input_dir : Vector3

var speed := 400.0
var fire_rate := 0.4

var fire_round_chance := 0.0
var ammo_size := 1.0

var can_shoot := true

var base_rotation = 0

@onready var arrow_scene = preload("res://scenes/arrow.tscn")

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	$Model/player/AnimationPlayer.play("RunForward")

func calculate_fire_rate():
	fire_rate *= 0.85

func calculate_speed():
	speed *= 1.025
	$SpeedLabel.visible = true
	$SpeedLabel.text = str(speed)

func _physics_process(delta):
	handle_aim()
	handle_shooting()
	
	input_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_dir.z = Input.get_action_strength("down") - Input.get_action_strength("up")
	input_dir.y = 0
	
	input_dir = input_dir.normalized()
	base_rotation
	
	if input_dir != Vector3.ZERO:
		base_rotation = -Vector2(input_dir.x, input_dir.z).angle() + (PI/2)
		
	#$Model/Wheels.rotation.y = lerp_angle($Model/Wheels.rotation.y, base_rotation, 15 * delta)
	
	velocity = lerp(velocity, speed * input_dir * delta, 10 * delta)
	
	handle_death()
	move_and_slide()

func handle_death():
	if World.player_health <= 0:
		pass

func handle_shooting():
	if Input.is_action_pressed("shoot"):
		if can_shoot:
			$Animator.stop()
			$Animator.play("Recoil")
			var arrow = arrow_scene.instantiate()
			arrow.position = $Model/Bow/Bow/ArrowPos.global_position
			arrow.rotation.y = $Model/Bow/Bow/ArrowPos.global_rotation.y + (PI/2)
			var fire_chance = rng.randf()
			if fire_chance <= fire_round_chance:
				arrow.on_fire = true
			arrow.size = ammo_size
			get_parent().add_child(arrow)
			can_shoot = false
			await get_tree().create_timer(fire_rate).timeout
			can_shoot = true

func handle_aim():
	var mouse_pos = get_viewport().get_mouse_position()
	ray_origin = $Camera.project_ray_origin(mouse_pos)
	ray_target = ray_origin + $Camera.project_ray_normal(mouse_pos) * 2000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
	query.collision_mask = -2147483648
	query.collide_with_areas = true
	var intersection = space_state.intersect_ray(query)
	
	if not intersection.is_empty():
		var pos = intersection.position
		var look_to = Vector3(pos.x, position.y, pos.z)
		
		$Model.look_at(look_to, Vector3.UP)
		
		# lock x and z axis
		$Model.rotation.x = 0
		$Model.rotation.z = 0

func collect_powerup(type : String):
	if type == "quickfire":
		calculate_fire_rate()
	elif type == "mushroom":
		ammo_size += 0.2
	elif type == "fire":
		fire_round_chance += 0.01
	elif type == "speed":
		calculate_speed()
	elif type == "heal":
		World.player_health += 1
