@tool
extends MeshInstance3D

@export var generate = true:
	set(input):
		generate_chunk()

const chunk_size : int = 32

func generate_chunk():
	var noise = FastNoiseLite.new()
	noise.frequency = 0.1
	var chunk = ImageTexture3D.new()
	chunk = noise.get_image_3d(chunk_size, chunk_size, chunk_size, false, true)
	set_instance_shader_parameter("chunk", chunk)
