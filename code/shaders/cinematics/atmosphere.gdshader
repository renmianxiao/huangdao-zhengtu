shader_type canvas_item;
render_mode unshaded;

uniform float clock_seconds = 0.0;
uniform float strength = 0.0;
uniform float ending = 0.0;
uniform vec2 aspect = vec2(1.777778, 1.0);
uniform vec2 light_position = vec2(0.65, 0.22);
uniform vec3 light_color : source_color = vec3(1.0, 0.93, 0.78);
uniform vec3 fog_color : source_color = vec3(0.934, 0.955, 0.912);
uniform float light_strength = 0.045;
uniform float ray_strength = 0.12;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + 1.0), f.x), f.y);
}

float fbm(vec2 p) {
	return noise(p) * 0.57 + noise(p * 2.03 + 7.1) * 0.28 + noise(p * 4.11) * 0.15;
}

void fragment() {
	vec2 p = UV;
	float slow_drift = clock_seconds * 0.018;
	float fog_noise = fbm(p * vec2(4.1, 8.0) + vec2(-slow_drift, slow_drift * 0.25));
	float fog_noise2 = fbm(p * vec2(6.4, 12.0) + vec2(slow_drift * 0.7, 4.7));
	float valley = exp(-pow((p.y - 0.60 - (fog_noise - 0.5) * 0.18) * 8.5, 2.0));
	float foreground = exp(-pow((p.y - 0.86 - (fog_noise2 - 0.5) * 0.14) * 11.0, 2.0));
	float fog = valley * smoothstep(0.36, 0.74, fog_noise) * 0.23;
	fog += foreground * smoothstep(0.32, 0.78, fog_noise2) * 0.16;
	vec2 light_offset = (p - light_position) * aspect;
	float glow = exp(-dot(light_offset, light_offset) * 31.0) * light_strength;
	float ray = pow(max(0.0, sin(atan(light_offset.y, light_offset.x) * 7.0 + clock_seconds * 0.06)), 9.0);
	float rays = glow * ray * smoothstep(-0.02, 0.15, light_offset.y) * ray_strength;
	float alpha = (fog + glow + rays) * strength;
	vec3 color = mix(fog_color, light_color, (glow + rays) / max(0.001, fog + glow + rays));
	float closing_fog = ending * (0.10 + fog_noise * 0.15);
	COLOR = vec4(mix(color, vec3(0.95, 0.936, 0.897), ending), min(0.46, alpha + closing_fog));
}
