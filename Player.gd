extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 8
var gravity: int = 18
@onready var neck := $Neck
@onready var camera := $Neck/Camera

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	#camera
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.01)
			camera.rotate_x(-event.relative.y * 0.01)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		if event.is_action_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	#movement
	if Input.is_action_pressed("Jump"):
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_pressed("Crouch"):
		velocity.y = -JUMP_VELOCITY
	else:
		velocity.y = 0
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
