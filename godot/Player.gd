extends KinematicBody

# Credit: the good Garbaj, https://github.com/GarbajYT/godot_updated_fps_controller

var speed = 11
const ACCEL_DEFAULT = 7
const ACCEL_AIR = 1
onready var accel = ACCEL_DEFAULT
var gravity = 9.8
var jump = 10

var cam_accel = 40
var mouse_sense = 0.12
var snap

var direction = Vector3()
var velocity = Vector3()
var gravity_vec = Vector3()
var movement = Vector3()

onready var head = $Head
onready var camera = $Head/Camera

var menu_open = false
var faucet_menu = load("res://ConfigMenu.tscn")
var menu

func _ready():
	#hides the cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Global.reticle = $Reticle/Target
	
func _input(event):
	#get mouse input for camera rotation
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))

func _process(delta):
	if menu_open == false:
		#camera physics interpolation to reduce physics jitter on high refresh-rate monitors
		if Engine.get_frames_per_second() > Engine.iterations_per_second:
			camera.set_as_toplevel(true)
			camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(head.global_transform.origin, cam_accel * delta)
			camera.rotation.y = rotation.y
			camera.rotation.x = head.rotation.x
		else:
			camera.set_as_toplevel(false)
			camera.global_transform = head.global_transform
		
func _physics_process(delta):
	
	if Input.is_action_just_pressed("menu"):
		if menu_open == false:
			menu_open = true
			var new_menu = faucet_menu.instance()
			add_child(new_menu)
			new_menu.player = self
			menu = new_menu
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			menu_open = false
			menu.queue_free()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if menu_open == false:
		#get keyboard input
		direction = Vector3.ZERO
		var h_rot = global_transform.basis.get_euler().y
		var f_input = Input.get_action_strength("back") - Input.get_action_strength("forward")
		var h_input = Input.get_action_strength("right") - Input.get_action_strength("left")
		direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
		
		#jumping and gravity
		if is_on_floor():
			snap = -get_floor_normal()
			accel = ACCEL_DEFAULT
			gravity_vec = Vector3.ZERO
		else:
			snap = Vector3.DOWN
			accel = ACCEL_AIR
			gravity_vec += Vector3.DOWN * gravity * delta
			
		if Input.is_action_just_pressed("jump") and is_on_floor():
			snap = Vector3.ZERO
			gravity_vec = Vector3.UP * jump
		
		#make it move
		velocity = velocity.linear_interpolate(direction * speed, accel * delta)
		movement = velocity + gravity_vec
		
		move_and_slide_with_snap(movement, snap, Vector3.UP)
	
