shader_type canvas_item;
render_mode unshaded;

uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform vec2 origin = vec2(0.5, 0.48);
uniform vec2 aspect = vec2(1.777778, 1.0);
uniform float softness = 0.065;
uniform float desaturate = 0.0;
// Zero selects a radius that covers all corners for the configured origin.
uniform float full_radius = 0.0;

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
	return noise(p) * 0.52 + noise(p * 2.07 + 3.7) * 0.27
		+ noise(p * 4.21 + 9.2) * 0.14 + noise(p * 8.43) * 0.07;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 p = (UV - origin) * aspect;
	float ink = fbm(UV * 7.0);
	float vein = fbm(UV * 33.0 + ink * 3.0);
	float distance_from_origin = length(p) + (ink - 0.5) * 0.26 + (vein - 0.5) * 0.055;
	float corner_radius = length(max(origin, vec2(1.0) - origin) * aspect) + 0.23;
	float final_radius = max(full_radius, corner_radius);
	float radius = mix(-0.12, final_radius, reveal);
	float coverage = 1.0 - smoothstep(radius - softness, radius + softness, distance_from_origin);
	float edge = (1.0 - smoothstep(0.0, softness * 2.0, abs(distance_from_origin - radius))) * 0.12;
	float luminance = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	tex.rgb = mix(tex.rgb, vec3(luminance) * vec3(1.02, 1.005, 0.97), desaturate);
	tex.rgb *= 1.0 - edge;
	COLOR = vec4(tex.rgb, tex.a * coverage * opacity);
}
