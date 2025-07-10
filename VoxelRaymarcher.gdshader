shader_type spatial;
render_mode unshaded;

const int CHUNK_SIZE = 64;
const float VOXEL_SIZE = 1.0 / float(CHUNK_SIZE);
const float MAX_DIST = 100.0;
const int MAX_STEPS = 512;

global uniform vec3 world_camera;     // Ray origin
global uniform vec3 world_direction;  // Forward (normalized)

uniform sampler2D atlas;
uniform float atlas_columns;
global uniform sampler2DArray chunks;

global uniform float aspect_ratio; // Pass this from GDScript as (viewport_width / viewport_height)

vec3 get_ray_direction(vec2 uv, vec3 forward) {
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 right = normalize(cross(forward, up));
	up = normalize(cross(right, forward));

	vec2 screen_uv = uv * 2.0 - 1.0;
	screen_uv.y = -screen_uv.y; // flip Y axis

	const float fov = 1.0; // scale factor, not actual FOV degrees
	screen_uv.x *= aspect_ratio; // ← fix the stretching

	return normalize(forward + screen_uv.x * right * fov + screen_uv.y * up * fov);
}

ivec3 to_voxel(vec3 p) {
	vec3 t = (p + 0.5) * float(CHUNK_SIZE);
	return ivec3(floor(t));
}

int get_voxel(ivec3 coord) {
	if (any(lessThan(coord, ivec3(0))) || any(greaterThanEqual(coord, ivec3(CHUNK_SIZE))))
		return 0;

	vec2 uv = (vec2(coord.xy) + vec2(0.5)) / float(CHUNK_SIZE);
	int index = coord.z;
	float value = texture(chunks, vec3(uv, float(index))).r;
	return int(value * 255.0);
}

struct voxel {
	int type;
	float dist;
	vec3 normal;
};

voxel RayMarch(vec3 ro, vec3 rd) {
	ivec3 voxel_p = to_voxel(ro);
	vec3 step = sign(rd);
	vec3 inv_rd = 1.0 / rd;
	vec3 tDelta = abs(inv_rd) * VOXEL_SIZE;

	vec3 voxel_boundary = (vec3(voxel_p) + vec3(0.5) + step * 0.5) * VOXEL_SIZE - 0.5;
	vec3 tMax = (voxel_boundary - ro) * inv_rd;

	voxel v;
	v.dist = 0.0;
	v.normal = vec3(0.0);

	for (int i = 0; i < MAX_STEPS; i++) {
		v.type = get_voxel(voxel_p);
		if (v.type != 0) return v;

		if (tMax.x < tMax.y && tMax.x < tMax.z) {
			voxel_p.x += int(step.x);
			v.dist = tMax.x;
			tMax.x += tDelta.x;
			v.normal = vec3(step.x, 0.0, 0.0);
		} else if (tMax.y < tMax.z) {
			voxel_p.y += int(step.y);
			v.dist = tMax.y;
			tMax.y += tDelta.y;
			v.normal = vec3(0.0, step.y, 0.0);
		} else {
			voxel_p.z += int(step.z);
			v.dist = tMax.z;
			tMax.z += tDelta.z;
			v.normal = vec3(0.0, 0.0, step.z);
		}
	}

	v.dist = MAX_DIST;
	return v;
}

float get_face(vec3 normal) {
	if (normal.y == 1.0) return 5.0;
	if (normal.x == 1.0) return 4.0;
	if (normal.x == -1.0) return 3.0;
	if (normal.z == 1.0) return 2.0;
	if (normal.z == -1.0) return 1.0;
	if (normal.y == -1.0) return 0.0;
	return 0.0;
}

void fragment() {
	vec3 ro = world_camera;
	vec3 rd = get_ray_direction(SCREEN_UV, world_direction);
	ro += rd * 1e-4;

	voxel v = RayMarch(ro, rd);
	if (v.dist >= MAX_DIST) discard;

	vec3 hit_voxel_pos = fract((ro + rd * v.dist + 0.5) * float(CHUNK_SIZE));
	float face_index = get_face(v.normal);

	vec2 tex_uv;
	if (v.normal.y != 0.0) {
		tex_uv = hit_voxel_pos.xz;
	} else if (v.normal.x != 0.0) {
		tex_uv = hit_voxel_pos.zy * vec2(1.0, -1.0) + vec2(0.0, 1.0);
	} else {
		tex_uv = hit_voxel_pos.xy * vec2(1.0, -1.0) + vec2(0.0, 1.0);
	}

	vec2 tile_size = 1.0 / vec2(atlas_columns, 6.0);
	vec2 tile_index = vec2(float(v.type - 1), face_index);
	vec2 tile_uv = (tex_uv + tile_index) * tile_size;
	ALBEDO = texture(atlas, tile_uv).rgb;
}