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
	var chunk = ImageTexture3D.new()
	for z in chunk_size:
		var image = Image.new()
		image.create(chunk_size,chunk_size,chunk_size,Image.FORMAT_R8)
		for x in chunk_size:
			for y in chunk_size:
				image.set_pixel(x,y,Color(get_block(x,y,z),0.0,0.0))
	set_instance_shader_parameter("chunk", chunk)

func get_block(x : float,y : float ,z : float) -> float:
	if noise.get_noise_3d(x,y,z) > 0:
		return 0.0
	else:
		return 1.0
