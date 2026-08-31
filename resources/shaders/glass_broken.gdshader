shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

uniform float fall_progress : hint_range(0.0, 1.0) = 0.0;
uniform float blur_lod : hint_range(0.0, 5.0) = 0.0;
uniform float glass_alpha : hint_range(0.0, 1.0) = 0.0;

uniform int pieces_x = 5;
uniform int pieces_y = 3;

// Multiplies the guaranteed falling distance
// (1.0 = "normal" fall, higher values make the piece
// accelerate and leave the screen faster).
uniform float gravity : hint_range(0.5, 3.0) = 1.15;
uniform float scatter : hint_range(0.0, 1.0) = 0.22;
uniform float rotation_amount : hint_range(0.0, 4.0) = 1.0;

uniform float point_jitter : hint_range(0.0, 0.48) = 0.34;
uniform float delay_variation : hint_range(0.0, 0.8) = 0.28;

// Extra margin (in screen heights) below the bottom edge
// to guarantee the piece is completely out of view
// when fall_progress reaches 1.0.
uniform float exit_margin : hint_range(0.0, 1.0) = 0.35;

uniform float edge_thickness : hint_range(0.0005, 0.05) = 0.01;
uniform float edge_brightness : hint_range(0.0, 2.0) = 0.35;

// Optional additional alpha fade near the end of the fall
// (1.0 = no fade).
uniform float alpha_fade_start : hint_range(0.0, 1.0) = 1.0;

const int SEARCH_RADIUS = 1;
const int MAX_ROWS = 32; // Safety limit for the row search loop
const int MAX_COLUMNS = 32; // Safety limit for the column search loop

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
	return vec2(
		hash12(p + vec2(1.23, 4.56)),
		hash12(p + vec2(7.89, 0.12))
	);
}

mat2 rot(float a) {
	float s = sin(a);
	float c = cos(a);
	return mat2(vec2(c, -s), vec2(s, c));
}

vec2 cell_point(vec2 cell_id) {
	vec2 h = hash22(cell_id);
	return cell_id + 0.5 + (h - 0.5) * (point_jitter * 2.0);
}

// Finds the closest Voronoi owner (cell/point) to p,
// along with an approximate distance to the cell boundary.
void voronoi_info(vec2 p, out vec2 owner_cell, out vec2 owner_point, out float edge_dist) {
	vec2 base = floor(p);

	float best_d = 1e20;
	float second_d = 1e20;
	vec2 best_cell = vec2(0.0);
	vec2 best_point = vec2(0.0);

	for (int j = -SEARCH_RADIUS; j <= SEARCH_RADIUS; j++) {
		for (int i = -SEARCH_RADIUS; i <= SEARCH_RADIUS; i++) {
			vec2 c = base + vec2(float(i), float(j));
			vec2 pt = cell_point(c);
			float d = distance(p, pt);

			if (d < best_d) {
				second_d = best_d;
				best_d = d;
				best_cell = c;
				best_point = pt;
			} else if (d < second_d) {
				second_d = d;
			}
		}
	}

	owner_cell = best_cell;
	owner_point = best_point;
	edge_dist = second_d - best_d;
}

// Piece transform:
// Ensures that, in the worst-case scenario (t = 1),
// the piece has already moved completely below the screen
// (plus a safety margin), preventing it from stopping
// halfway or overshooting prematurely.
void piece_transform(
	vec2 piece_cell,
	vec2 point,
	vec2 grid,
	out float t,
	out vec2 piece_offset_uv,
	out float piece_angle
) {
	float rnd  = hash12(piece_cell);
	float rnd2 = hash12(piece_cell + 17.37);
	float rnd3 = hash12(piece_cell + 91.11);

	float delay = rnd * delay_variation;
	t = clamp((fall_progress - delay) / max(0.0001, 1.0 - delay), 0.0, 1.0);

	float center_y = point.y / grid.y;

	// Distance required for this piece to fully leave the screen.
	float needed = (1.0 - center_y) + exit_margin;

	float speed_variance = 0.6 + rnd2 * 0.8;
	float fall_y = needed * (t * t) * gravity * speed_variance;

	float drift_x = (rnd2 - 0.5) * scatter * t;

	piece_offset_uv = vec2(drift_x, fall_y);
	piece_angle = (rnd3 - 0.5) * rotation_amount * t;
}

vec4 sample_screen(vec2 uv, vec2 pixel_size) {
	if (blur_lod <= 0.001) {
		vec4 source = texture(screen_tex, uv, 0.0);
		source.a = 1.0;
		return source;
	}

	vec2 offset = pixel_size * (1.0 + blur_lod * 2.0);
	vec4 color = texture(screen_tex, uv, blur_lod) * 0.25;
	color += texture(screen_tex, uv + vec2(offset.x, 0.0), blur_lod) * 0.125;
	color += texture(screen_tex, uv - vec2(offset.x, 0.0), blur_lod) * 0.125;
	color += texture(screen_tex, uv + vec2(0.0, offset.y), blur_lod) * 0.125;
	color += texture(screen_tex, uv - vec2(0.0, offset.y), blur_lod) * 0.125;
	color += texture(screen_tex, uv + offset, blur_lod) * 0.0625;
	color += texture(screen_tex, uv - offset, blur_lod) * 0.0625;
	color += texture(screen_tex, uv + vec2(offset.x, -offset.y), blur_lod) * 0.0625;
	color += texture(screen_tex, uv + vec2(-offset.x, offset.y), blur_lod) * 0.0625;
	color.a = 1.0;
	return color;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 pixel_size = SCREEN_PIXEL_SIZE;
	vec2 grid = vec2(float(pieces_x), float(pieces_y));

	vec4 result = vec4(0.0);
	bool found = false;
	float found_edge = 0.0;
	float found_t = 0.0;

	// Scan every piece so the candidate set stays the same across
	// the original grid boundaries. This avoids straight seams when
	// overlapping falling pieces are resolved in a different order.
	for (int iy = 0; iy < MAX_ROWS; iy++) {
		if (iy >= pieces_y) break;

		for (int ix = 0; ix < MAX_COLUMNS; ix++) {
			if (ix >= pieces_x) break;

			vec2 cell_id = vec2(float(ix), float(iy));
			vec2 point = cell_point(cell_id);
			vec2 piece_center_uv = point / grid;

			float t;
			vec2 offset;
			float angle;
			piece_transform(cell_id, point, grid, t, offset, angle);

			vec2 rel_now = uv - piece_center_uv;
			vec2 uv_from = piece_center_uv + rot(-angle) * (rel_now - offset);

			if (uv_from.x < 0.0 || uv_from.y < 0.0 || uv_from.x > 1.0 || uv_from.y > 1.0) {
				continue;
			}

			vec2 p_from = uv_from * grid;
			vec2 from_cell;
			vec2 from_point;
			float from_edge;
			voronoi_info(p_from, from_cell, from_point, from_edge);

			if (distance(from_cell, cell_id) > 0.001) continue;

			result = sample_screen(uv_from, pixel_size);
			found_edge = from_edge;
			found_t = t;
			found = true;
		}
	}

	if (!found) {
		COLOR = vec4(0.0, 0.0, 0.0, glass_alpha);
	} else {
		float edge = 1.0 - smoothstep(0.0, edge_thickness, found_edge);
		result.rgb += edge * edge_brightness;

		float fade = 1.0;
		if (alpha_fade_start < 1.0) {
			fade = 1.0 - smoothstep(alpha_fade_start, 1.0, found_t);
		}
		result.a *= fade * glass_alpha;

		COLOR = result;
	}
}
