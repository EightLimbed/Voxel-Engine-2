shader_type spatial;
render_mode unshaded;
//render_mode unshaded, world_vertex_coords; // to raymarch in world space

varying vec3 world_camera;
varying vec3 world_position;

const int MAX_STEPS = 32;
const float MAX_DIST = 32.0;
const float SURF_DIST = 1e-4;

const float STEP_SIZE = 1.0/32.0;

uniform int[32768] chunk;

//JUST USE POSITIONAL VALUES OF P!
float GetDist(vec3 p){
	vec3 bp = vec3(0,0,1.0/32.0);
	vec3 bu = vec3(0,1.0/32.0,0);
	float d;
	if (p.z<0.0){
		d = length(max(abs(p+bp)-STEP_SIZE/2.0,0));
	}
	if (p.z>0.0){
		d = length(max(abs(p-bp)-STEP_SIZE/2.0,0));
	}
	if (p.y>STEP_SIZE/1.8){
		d = length(max(abs(p-bu)-STEP_SIZE/2.0,0));
	}
	if (p.y>STEP_SIZE*1.5){
		d = length(max(abs(p-2.0*bu)-STEP_SIZE/2.0,0));
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

vec3 GetNormal(vec3 p) {
	vec2 e = vec2(1e-2, 0);

	vec3 n = GetDist(p) - vec3(
		GetDist(p - e.xyy),
		GetDist(p - e.yxy),
		GetDist(p - e.yyx)
	);

	return normalize(n);
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
		vec3 n = GetNormal(p);
		col = n.rgb;
	}

	ALBEDO = col;
}