@tool
extends MeshInstance3D

var noise = FastNoiseLite
var random = RandomNumberGenerator
@export var chunk : ImageTexture3D

@export var generate = true:
	set(input):
		generate_chunk()

const chunk_size : int = 32

func _ready() -> void:
	generate_chunk()
	pass

func generate_chunk():
	noise = FastNoiseLite.new()
	noise.frequency = 0.01
	random = RandomNumberGenerator.new()
	noise.seed = random.randi()
	var images : Array[Image] = []
	chunk = ImageTexture3D.new()
	for x in range(chunk_size):
		var data : PackedByteArray
		#data.resize(3*chunk_size^2)
		for y in range(chunk_size):
			for z in range(chunk_size):
				data.append(get_block(x,y,z))
				data.append(0)
				data.append(0)
		var image : Image = Image.create_from_data(chunk_size, chunk_size, false,Image.FORMAT_RGB8,data)
		images.append(image)
	chunk.create(Image.FORMAT_RGB8, chunk_size, chunk_size, chunk_size, false, images)
	mesh.material.set("shader_parameter/chunk",chunk);

func get_block(x : int,y : int ,z : int) -> int:
	x+=position.x*chunk_size
	y+=position.y*chunk_size
	z+=position.z*chunk_size
	var height = noise.get_noise_2d(x,z)*64+chunk_size/2.0
	if height > y:
		return 2
	elif height > y-1:
		return 1
	else:
		return 0
