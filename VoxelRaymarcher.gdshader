shader_type spatial;
render_mode unshaded;

const int CHUNK_SIZE = 32;
const float VOXEL_SIZE = 1.0 / float(CHUNK_SIZE);
const float MAX_DIST = 100.0;
const int MAX_STEPS = 128;

varying vec3 world_camera;
varying vec3 world_position;

uniform sampler3D chunk;

// Convert world position to voxel grid coords
ivec3 to_voxel(vec3 p) {
	return ivec3(floor((p + 0.5) * float(CHUNK_SIZE)));
}

// Get 1D array index from voxel coords
int get_index(ivec3 coord) {
	if (any(lessThan(coord, ivec3(0))) || any(greaterThanEqual(coord, ivec3(CHUNK_SIZE))))
		return -1;
	return coord.x + coord.y * CHUNK_SIZE + coord.z * CHUNK_SIZE * CHUNK_SIZE;
}

// Digital Differential Analyzer voxel ray traversal
float RayMarch(vec3 ro, vec3 rd, out vec3 hit_pos, out ivec3 hit_voxel) {
	vec3 p = ro;
	ivec3 voxel = to_voxel(p);

	vec3 step = sign(rd);
	vec3 tDelta = abs(vec3(1.0) / rd) * VOXEL_SIZE;
	vec3 voxel_boundary = (vec3(voxel) / float(CHUNK_SIZE)) - 0.5;
	voxel_boundary += step * VOXEL_SIZE;
	vec3 tMax = abs((voxel_boundary - p) / rd);

	for (int i = 0; i < MAX_STEPS; i++) {
		int index = get_index(voxel);
		if (index >= 0 && chunk[index] != 0) {
			hit_pos = p;
			hit_voxel = voxel;
			return length(p - ro);
		}

		// Step to next voxel
		if (tMax.x < tMax.y) {
			if (tMax.x < tMax.z) {
				tMax.x += tDelta.x;
				voxel.x += int(step.x);
			} else {
				tMax.z += tDelta.z;
				voxel.z += int(step.z);
			}
		} else {
			if (tMax.y < tMax.z) {
				tMax.y += tDelta.y;
				voxel.y += int(step.y);
			} else {
				tMax.z += tDelta.z;
				voxel.z += int(step.z);
			}
		}
		p = ro + min(tMax.x, min(tMax.y, tMax.z)) * rd;
	}

	return MAX_DIST;
}

void vertex() {
	world_position = VERTEX;
	world_camera = (inverse(MODELVIEW_MATRIX) * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
}

void fragment() {
	vec3 ro = world_camera;
	vec3 rd = normalize(world_position - ro);

	vec3 hit_pos;
	ivec3 hit_voxel;
	float dist = RayMarch(ro, rd, hit_pos, hit_voxel);

	if (dist >= MAX_DIST) {
		discard;
	} else {
		// Simple lighting / fake normal
		vec3 col = vec3(hit_voxel) / float(CHUNK_SIZE); // unique color per voxel position
		ALBEDO = col;
	}
}