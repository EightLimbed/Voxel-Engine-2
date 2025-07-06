shader_type spatial;
render_mode unshaded;

const int CHUNK_SIZE = 32;
const float VOXEL_SIZE = 1.0 / float(CHUNK_SIZE);
const float MAX_DIST = 100.0;
const int MAX_STEPS = 256;
varying vec3 world_camera;
varying vec3 world_position;

uniform sampler3D chunk; // 3D voxel data stored as RGB8

// Convert world space [-0.5, 0.5] to texture space [0,1]
vec3 world_to_texcoord(vec3 p) {
	return (p+0.5);
}

// Convert world space to voxel grid coordinate
ivec3 to_voxel(vec3 p) {
	vec3 t = (p + 0.5) * float(CHUNK_SIZE);
	return ivec3(floor(t));
}

bool is_voxel_solid(ivec3 coord) {
	if (any(lessThan(coord, ivec3(0))) || any(greaterThanEqual(coord, ivec3(CHUNK_SIZE))))
		return false;

	vec3 uvw = (vec3(coord) + vec3(0.5)) / float(CHUNK_SIZE); // center of voxel texel
	float value = texture(chunk, uvw).r; // red channel only (R8)
	return value == 1.0;
}

float RayMarch(vec3 ro, vec3 rd, out vec3 hit_pos, out ivec3 hit_voxel) {
	rd = normalize(rd);
	vec3 p = ro;
	ivec3 voxel = to_voxel(p);

	vec3 step = sign(rd);
	vec3 inv_rd = 1.0 / rd;
	vec3 tDelta = abs(inv_rd) * VOXEL_SIZE;

	vec3 voxel_boundary = (vec3(voxel) + vec3(0.5) +step * 0.5) * VOXEL_SIZE - 0.5;
	vec3 tMax = (voxel_boundary - ro) * inv_rd;

	float t = 0.0;

	for (int i = 0; i < MAX_STEPS; i++) {
		if (is_voxel_solid(voxel)) {
			hit_pos = ro + rd * t;
			hit_voxel = voxel;
			return t;
		}

		if (tMax.x < tMax.y && tMax.x < tMax.z) {
			voxel.x += int(step.x);
			t = tMax.x;
			tMax.x += tDelta.x;
		} else if (tMax.y < tMax.z) {
			voxel.y += int(step.y);
			t = tMax.y;
			tMax.y += tDelta.y;
		} else {
			voxel.z += int(step.z);
			t = tMax.z;
			tMax.z += tDelta.z;
		}
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
	ro += rd * 1e-4;
	vec3 hit_pos;
	ivec3 hit_voxel;
	float dist = RayMarch(ro, rd, hit_pos, hit_voxel);

	if (dist >= MAX_DIST) {
		discard;
	} else {
		// Simple color based on voxel position
		ALBEDO = vec3(hit_voxel) / float(CHUNK_SIZE);
	}
}