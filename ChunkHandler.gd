extends Node3D

@export var chunk_scene : PackedScene
var noise = FastNoiseLite
var random = RandomNumberGenerator

const chunk_size : int = 64
@export var render_distance : int = 2

func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.frequency = 0.01
	random = RandomNumberGenerator.new()
	noise.seed = random.randi()
	RenderingServer.global_shader_parameter_set("map_size", render_distance*chunk_size)
	generate_start_chunks()

func create_slice(x : int, pos) -> Image:
	var data : PackedByteArray
	for y in range(chunk_size):
		for z in range(chunk_size):
			data.append(get_block(Vector3(x,y,z)+pos*chunk_size))
			data.append(0)
			data.append(0)
	return Image.create_from_data(chunk_size, chunk_size, false,Image.FORMAT_RGB8,data)

func generate_start_chunks() -> void:
	var images : Array[Image] = []
	# goes through all starting chunks
	for xt in range(render_distance):
		for yt in range(render_distance):
			for zt in range(render_distance):
				#creates chunk at desired position, as chunk_size* layers of blocks
				var chunk_pos : Vector3 = Vector3(xt-render_distance/2,render_distance/2-yt,zt-render_distance/2)
				for x in range(chunk_size):
					var image : Image = create_slice(x, chunk_pos)
					images.append(image)
	var chunk := Texture2DArray.new()
	chunk.create_from_images(images)
	RenderingServer.global_shader_parameter_set("chunks", chunk)

func get_block(pos : Vector3) -> int:
	var height = noise.get_noise_2d(pos.x,pos.z)*48+chunk_size/2.0
	if height > pos.y:
		return 2
	elif height > pos.y-1:
		return 1
	else:
		return 0
