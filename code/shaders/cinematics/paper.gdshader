shader_type canvas_item;
render_mode unshaded;

uniform vec2 canvas_size = vec2(1920.0, 1080.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + 1.0), f.x), f.y);
}

void fragment() {
	vec2 p = UV * canvas_size;
	float grain = hash(floor(p)) - 0.5;
	float fibers = noise(p * vec2(0.12, 0.8));
	float wash = noise(p * 0.006);
	vec3 paper = vec3(0.951, 0.936, 0.897);
	paper += grain * 0.025 + (fibers - 0.5) * 0.016 + (wash - 0.5) * 0.022;
	float edge = length((UV - 0.5) * vec2(1.0, 0.75));
	paper -= smoothstep(0.25, 0.69, edge) * vec3(0.026, 0.027, 0.028);
	COLOR = vec4(paper, 1.0);
}
