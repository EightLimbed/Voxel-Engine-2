@tool
extends MeshInstance3D

var noise = FastNoiseLite
var random = RandomNumberGenerator

@export var generate = true:
	set(input):
		generate_chunk()

const chunk_size : int = 32

func generate_chunk():
	noise = FastNoiseLite.new()
	random = RandomNumberGenerator.new()
	noise.seed = random.randi()
	var chunk : PackedInt32Array = []
	chunk.resize(32*32*32)
	for x in chunk_size:
		for y in chunk_size:
			for z in chunk_size:
				chunk[z + 32 * (y + 32 * x)] = get_block(x,y,z)
	set_instance_shader_parameter("chunk", chunk)
	print(chunk[1000])
	print(get_instance_shader_parameter("chunk")[1000])

func get_block(x : float,y : float ,z : float):
	return 1
	if noise.get_noise_3d(x,y,z) > 0:
		return 0
	else:
		return 1
