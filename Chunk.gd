@tool
extends MeshInstance3D
@export var generate : bool = true
var noise = FastNoiseLite

func generate_chunk():
	var texture = NoiseTexture3D
	
	set_instance_shader_parameter("c", chunk_data)

func _process(delta: float) -> void:
	if generate:
		generate_chunk()
		generate = false

func get_block_noise(pos: Vector3) -> int:
	var hills = noise.get_noise_3d(pos.x, pos.y, pos.z)
	if hills > 0.1:
		return 1.0
	return 0.0
