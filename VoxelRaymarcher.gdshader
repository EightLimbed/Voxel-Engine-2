shader_type spatial;
render_mode unshaded;

const int CHUNK_SIZE = 32;
const float VOXEL_SIZE = 1.0 / float(CHUNK_SIZE);
const float MAX_DIST = 100.0;
const int MAX_STEPS = 256;
varying vec3 world_camera;
varying vec3 world_position;

uniform sampler2D atlas;
uniform float atlas_columns;
uniform sampler3D chunk; // 3D voxel data stored as RGB8

uniform vec3 frozen_camera;
uniform bool freeze_view = false;

// Convert world space [-0.5, 0.5] to texture space [0,1]
vec3 world_to_texcoord(vec3 p) {
	return (p+0.5);
}

// Convert world space to voxel grid coordinate
ivec3 to_voxel(vec3 p) {
	vec3 t = (p + 0.5) * float(CHUNK_SIZE);
	return ivec3(floor(t));
}

int get_voxel(ivec3 coord) {
	if (any(lessThan(coord, ivec3(0))) || any(greaterThanEqual(coord, ivec3(CHUNK_SIZE))))
		return 0;

	vec3 uvw = (vec3(coord) + vec3(0.5)) / float(CHUNK_SIZE); // center of voxel texel
	float value = texture(chunk, uvw).r; // red channel only (R8)
	return int(value*255.0);
}

struct voxel{
	int type;
	float dist;
};

voxel RayMarch(vec3 ro, vec3 rd, out vec3 hit_pos, out ivec3 hit_voxel) {
	rd = normalize(rd);
	vec3 p = ro;
	ivec3 voxel_p = to_voxel(p);

	vec3 step = sign(rd);
	vec3 inv_rd = 1.0 / rd;
	vec3 tDelta = abs(inv_rd) * VOXEL_SIZE;

	vec3 voxel_boundary = (vec3(voxel_p) + vec3(0.5) +step * 0.5) * VOXEL_SIZE - 0.5;
	vec3 tMax = (voxel_boundary - ro) * inv_rd;
	voxel v;
	v.dist = 0.0;

	for (int i = 0; i < MAX_STEPS; i++) {
		v.type = get_voxel(voxel_p);
		if (v.type != 0) {
			hit_pos = ro + rd * v.dist;
			hit_voxel = voxel_p;
			return v;
		}

		if (tMax.x < tMax.y && tMax.x < tMax.z) {
			voxel_p.x += int(step.x);
			v.dist = tMax.x;
			tMax.x += tDelta.x;
		} else if (tMax.y < tMax.z) {
			voxel_p.y += int(step.y);
			v.dist = tMax.y;
			tMax.y += tDelta.y;
		} else {
			voxel_p.z += int(step.z);
			v.dist = tMax.z;
			tMax.z += tDelta.z;
		}
	}
	v.dist = MAX_DIST;
	return v;
}

void vertex() {
	world_position = VERTEX;
	world_camera = (inverse(MODELVIEW_MATRIX) * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
}

void fragment() {
	//can freeze ray origin
	vec3 ro = freeze_view ? frozen_camera : world_camera;
	vec3 rd = normalize(world_position - ro);
	ro += rd * 1e-4;
	vec3 hit_pos;
	ivec3 hit_voxel;
	voxel v = RayMarch(ro, rd, hit_pos, hit_voxel);

	if (v.dist >= MAX_DIST) {
		discard;
	} else {
		//finds what orientation to apply
		// convert voxel hit position to local face UV
		vec2 uv = fract((hit_pos.xy + 0.5) * float(CHUNK_SIZE));

		// compute UV in atlas
		vec2 tile_uv = (vec2(float(v.type)-1.0) + uv)/atlas_columns;
		ALBEDO = texture(atlas, tile_uv).rgb;
	}
}