shader_type spatial;
render_mode unshaded;
//render_mode unshaded, world_vertex_coords; // to raymarch in world space

varying vec3 world_camera;
varying vec3 world_position;

const int CHUNK_SIZE = 32;
const int MAX_STEPS = 32;
const float MAX_DIST = 32.0;
const float SURF_DIST = 1e-3;

const float STEP_SIZE = 1.0/float(CHUNK_SIZE);

uniform int[32768] chunk;

//JUST USE POSITIONAL VALUES OF P!
float GetDist(vec3 p){
	vec3 po = vec3(STEP_SIZE)/2.0;
	vec3 bu = vec3(0,1.0/32.0,0);
	float d = 0.0;
	if (p.y <= 0.0){
		d = length(max(abs(p-po+bu)-STEP_SIZE/2.0,0));
	}
	if (p.y >= 0.0){
		d = length(max(abs(p-po-bu)-STEP_SIZE/2.0,0));
	}
	return d;
}

float RayMarch(vec3 ro, vec3 rd) {
	float dO = 0.0;
	float dS;

	for (int i = 0; i < MAX_STEPS; i++)
	{
		vec3 p = ro + dO * rd;
		dS = GetDist(p);
		dO += dS;

		if (dS < SURF_DIST || dO > MAX_DIST)
			break;
	}
	return dO;
}

void vertex() {
	world_position = VERTEX;
	world_camera = (inverse(MODELVIEW_MATRIX) * vec4(0, 0, 0, 1)).xyz; //object space
	//world_camera = ( CAMERA_MATRIX  * vec4(0, 0, 0, 1)).xyz; //uncomment this to raymarch in world space
}

void fragment() {

	vec3 ro = world_camera;
	vec3 rd =  normalize(world_position - ro);

	vec3 col;

	float d = RayMarch(ro, rd);

	if (d >= MAX_DIST)
		discard;
	else
	{
		vec3 p = ro + rd * d;
		vec3 n = p;
		col = n.rgb;
	}

	ALBEDO = col*10.0;
}