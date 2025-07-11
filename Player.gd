extends Node

const SPEED = 0.5
const JUMP_VELOCITY = 0.5
const GRAVITY = 18.0

var pitch := 0.0
var yaw := 0.0
var world_direction := Vector3.FORWARD
var world_position := Vector3.ZERO
var sensitivity := 0.002

func _ready() -> void:
	RenderingServer.global_shader_parameter_set("aspect_ratio", float(get_viewport().size.x)/float(get_viewport().size.y))
	print(get_viewport().size.x/get_viewport().size.y)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			yaw -= event.relative.x * sensitivity
			pitch = clamp(pitch - event.relative.y * sensitivity, -PI / 2, PI / 2)
			# Construct direction from yaw/pitch
			world_direction = Vector3(
				cos(pitch) * sin(yaw),
				sin(pitch),
				cos(pitch) * cos(yaw)
			).normalized()

			RenderingServer.global_shader_parameter_set("world_direction", world_direction)

		if event.is_action_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	var sprint := int(Input.is_action_pressed("Sprint")) + 1

	# Get right and forward vectors based on yaw (no pitch in movement)
	var forward = Vector3(sin(yaw), 0, cos(yaw)).normalized()
	var right = Vector3(forward.z, 0, -forward.x).normalized()

	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	var move_dir := (right * input_dir.x + forward * input_dir.y).normalized()

	world_position -= move_dir * SPEED * sprint * delta

	if Input.is_action_pressed("Jump"):
		world_position.y += JUMP_VELOCITY * delta * sprint
	elif Input.is_action_pressed("Crouch"):
		world_position.y -= JUMP_VELOCITY * delta * sprint

	RenderingServer.global_shader_parameter_set("world_camera", world_position)
