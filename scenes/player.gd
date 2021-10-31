extends Spatial

onready var character = $character
var cam = {
	"speed":10,
	"current_speed":20,
	"mode":2,
}
var action = {
	"air_speed":0,
	"climb":false,
}

var direction = Vector3()
var direction2 = Vector3()
var velocity = Vector3()
var gravity = -27
var linear_speed = 6
var jump_height = 12
var walk_speed = 8
var run_speed = 16
var speed = 8
var fpv_camera_angle = 0
var fpv_mouse_sensitivity = 0.3
var tpv_camera_speed = 0.001

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	OS.set_window_position(Vector2(0,0))


func rotating(dir):
	var a  = atan2(dir.x* -1, dir.z* -1)
	var rot = character.get_rotation()
	if abs(rot.y-a) > PI:
		var m = PI * 2
		var d = fmod(a-rot.y,m)
		a = rot.y + (fmod(2 * d,m)-d)*0.2
	else:
		a = lerp(rot.y,a,0.1)
	character.rotation.y = a

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if event is InputEventMouseMotion:
		if cam.mode == 1:
# == First player view
			rotate_y(deg2rad(-event.relative.x * fpv_mouse_sensitivity))
			var change = -event.relative.y * fpv_mouse_sensitivity
			if change + fpv_camera_angle < 90 and change + fpv_camera_angle > -90:
				$head/Camera.rotate_x(deg2rad(change))
				fpv_camera_angle += change
		elif cam.mode == 2:
# == Third player view
			$head.rotate_y(-event.relative.x * tpv_camera_speed)
			$head/tpv.rotate_x(-event.relative.y * tpv_camera_speed)


func _process(delta):
	direction = Vector3()
	var aim = $head/tpv.get_global_transform().basis
	var walk = false
	var run = false
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
	if Input.is_key_pressed(KEY_W):
		direction -= aim.z
		walk = true
	if Input.is_key_pressed(KEY_S):
		direction += aim.z
		walk = true
	if Input.is_key_pressed(KEY_A):
		direction -= aim.x
		walk = true
	if Input.is_key_pressed(KEY_D):
		direction += aim.x
		walk = true
	if Input.is_key_pressed(KEY_SHIFT):
		run = true
	direction = direction.normalized()
	if walk and action.climb == false:
		direction2 = direction

		
#===On ground
	if character.is_on_floor():
		action.air_speed = 0
		action.walljump = Vector3()

#Jump
		if Input.is_key_pressed(KEY_SPACE) and character.cur_anim != "kong":#Input.is_action_just_pressed("jump"):
			velocity.y = jump_height
			character.animation("jump")
#Walk
		elif walk:
			rotating(direction)
			if velocity.y < 0.1:
				if run:
					speed = run_speed
					character.animation("run")
					if Input.is_key_pressed(KEY_E):
						character.cur_anim = "dive"
				else:
					speed = walk_speed
					character.animation("walk")
			if cam.current_speed > 2:
				cam.current_speed -= delta*5
#idle
		else:
			character.animation("stand")
			if cam.current_speed < cam.speed:
				cam.current_speed += delta*10
	else:
#camera
		if cam.current_speed > 2:
			cam.current_speed -= delta*10

#moves===========


#climb
		if run == false and action.climb == false and $character/climb1.is_colliding() and velocity.y <= 0 and $character/ground.is_colliding() == false:
			var p = $character/climb1.get_collision_point()
			$character/climb2.global_transform.origin.y=p.y
			$character/climb2.force_update_transform()
			$character/climb2.force_raycast_update()
			if $character/climb2.is_colliding() and $character/climb1.get_collider() == $character/climb2.get_collider():
				character.animation("climb")
				speed = walk_speed
				action.climb = true
				p = $character/climb2.get_collision_point()
				var n = $character/climb2.get_collision_normal()*-1
				direction = n
				direction2 = n
				character.global_transform.origin = p + (character.global_transform.origin-$character/armhook.global_transform.origin)
#walljump
		elif $character/climb2.is_colliding() and action.climb == false and direction2 != Vector3() and Input.is_key_pressed(KEY_SPACE) and velocity.y < 0 and $character/ground.is_colliding() == false:
			var d = todir(direction)
			if d != action.walljump:
				speed = walk_speed
				action.air_speed = 1
				direction = direction2 *-20
				velocity.y = jump_height
				rotating(direction)
				character.animation("jump")
				action.walljump = d
#jump from climb		
		elif Input.is_action_just_pressed("jump"):
			if action.climb:
				speed = walk_speed
				action.climb = false
				velocity.y = jump_height
				character.animation("jump")
				direction*=20
		rotating(direction2)

#moves===========
	

#climb
	if action.climb:
		velocity = Vector3()
		if run:
			action.climb = false
		var n = $character/climb2.get_collision_normal()
		var r = Vector2(n.x,n.z).angle()
		if Input.is_key_pressed(KEY_A) and $character/armhook/armclimbL.is_colliding():
			direction = Vector3(-sin(r),0,cos(r))*3
		elif Input.is_key_pressed(KEY_D) and $character/armhook/armclimbR.is_colliding():
			direction = Vector3(sin(r),0,-cos(r))*3
		else:
			return
	else:
#move & gravity
		velocity.y += gravity * delta
	var tv = velocity
	if action.air_speed == 0 or action.air_speed == 1:
		action.air_speed *=2
		tv = velocity.linear_interpolate(direction * speed,6 * delta)
	else:
		tv = velocity.linear_interpolate(direction * speed,1 * delta)

	velocity.x = tv.x
	velocity.z = tv.z
	velocity = character.move_and_slide(velocity,Vector3(0,1,0))

#camera
	$head.transform.origin += (character.transform.origin-$head.transform.origin)/cam.current_speed

	if character.transform.origin.y < -50:
		character.transform.origin = Vector3(0,0,0)

func todir(a):
	
	if a.x != 0:
		a.x = a.x/abs(a.x)
	else:
		a.x = 0
	if a.y != 0:
		a.y = a.y/abs(a.y)
	else:
		a.y = 0
	if a.z != 0:
		a.z = a.z/abs(a.z)
	else:
		a.z = 0
	return a