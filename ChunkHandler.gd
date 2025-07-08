extends Node3D

@export var chunk_scene : PackedScene
var noise = FastNoiseLite
var random = RandomNumberGenerator

# for remembery which chunks correspond to which index.
var chunk_indexes : Array[Vector3] = []

const chunk_size : int = 64
const render_distance : int = 3

func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.frequency = 0.01
	random = RandomNumberGenerator.new()
	noise.seed = random.randi()
	generate_start_chunks()

func create_chunk(pos, index) -> void:
	var instance = chunk_scene.instantiate()
	instance.position = pos
	instance.set_instance_shader_parameter("chunk_index", index)
	add_child(instance)
	# will work with loading chunks instead of regenerating later.

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
				var index = xt + render_distance * (yt + render_distance * zt)
				chunk_indexes.append(chunk_pos)
				create_chunk(chunk_pos, index)
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
