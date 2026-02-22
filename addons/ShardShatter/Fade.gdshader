shader_type spatial;
render_mode diffuse_toon;
render_mode specular_toon;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec3 color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 emission : source_color = vec3(1.0, 1.0, 1.0);
uniform float emission_multiplier : hint_range(0.0, 16.0) = 1.0;

void fragment() {
	ALBEDO = color;
	EMISSION = emission * emission_multiplier;
	ALPHA = progress;
}