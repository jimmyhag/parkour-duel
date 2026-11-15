// The grid of the blocks of a level (docs/specs/chase-arena.md): the colour of the block,
// crossed by lines every metre laid in the world, so that a distance reads by its squares
// on every face, whatever the size of the block. No image: the lines are worked out from
// the position of each pixel in the world.
shader_type spatial;

// The colour of the block, the kind of obstacle it is.
uniform vec3 colour : source_color = vec3(0.8);
// How wide a line is, in m, and how much darker than the block.
uniform float line_width : hint_range(0.0, 0.2) = 0.025;
uniform float line_darkness : hint_range(0.0, 1.0) = 0.35;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// The two world axes that lie across the face.
	vec3 facing = abs(world_normal);
	vec2 across = world_position.xy;
	if (facing.y >= facing.x && facing.y >= facing.z) {
		across = world_position.xz;
	} else if (facing.x >= facing.z) {
		across = world_position.zy;
	}
	// How far from the nearest whole metre, against how much that changes from a pixel to
	// the next: a line as sharp as the screen allows, at any distance.
	vec2 off_the_line = abs(fract(across + 0.5) - 0.5);
	vec2 blur = fwidth(across);
	vec2 on_the_line = 1.0 - smoothstep(vec2(line_width), vec2(line_width) + blur, off_the_line);
	float line = max(on_the_line.x, on_the_line.y);
	ALBEDO = mix(colour, colour * (1.0 - line_darkness), line);
	ROUGHNESS = 0.85;
}
