//each chunk contains 3d image corresponding to block types. shader sends out rays from every pixel, which step between pixels using DDA. 

shader_type spatial;

const float max_steps = 100.0;

varying vec3 world_camera;
varying vec3 world_position;

uniform sampler3D chunk;

//returns distance from edge of cube hit (p) to center of cube (pc), and type of cube (pc).
vec2 GetVoxel(vec3 p, vec3 cr){
	//might get rounding errors, as when looking back, 1.0s might get subtracted to 0.5s, and round back up.
	vec3 pc = round(p+sign(cr)*vec3(0.5));
	float d = length(max(abs(p+sign(cr)*vec3(0.5)-pc)-1.0/32.0, 0)); 
	float type = length(texture(chunk, pc));
	return vec2(d, type);
}

void vertex() {
	world_position = VERTEX;
	world_camera = (inverse(MODELVIEW_MATRIX) * vec4(0, 0, 0, 1)).xyz;
}

//finish DDA
//returns point distance from voxel (if one exists), and what type it is.
vec2 raymarch(vec3 cp, vec3 cr) {
	vec3 dda = abs(cp-max_steps*cr);
	for (int i = 0; i < int(max_steps); i++) {
		float d = 0.0;
		float type = 0.0;
		if (GetVoxel(p,cr) is ) {
			return vec2(d, type);
		}
	break;
	}
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 cp = world_camera;
	vec3 cr =  normalize(world_position - cp);
	
	vec2 d = raymarch(cp,cr);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
