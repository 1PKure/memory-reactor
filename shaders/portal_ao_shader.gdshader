shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float portal_speed = 1.0;
uniform float portal_intensity = 1.0;
uniform float vertical_stretch = 1.35;

uniform vec4 outer_color : source_color = vec4(0.85, 0.45, 1.00, 1.0);
uniform vec4 middle_color : source_color = vec4(0.95, 0.60, 1.00, 1.0);
uniform vec4 inner_color : source_color = vec4(0.75, 0.30, 0.95, 1.0);

float Ring(float distance_to_center, float radius, float width)
{
	float inner = smoothstep(radius - width, radius, distance_to_center);
	float outer = 1.0 - smoothstep(radius, radius + width, distance_to_center);
	return inner * outer;
}

void fragment()
{
	vec2 uv = UV * 2.0 - 1.0;

	float speed = max(portal_speed, 0.8);
	float intensity = max(portal_intensity, 0.8);

	float t = TIME * speed;

	vec2 portal_uv = vec2(uv.x * vertical_stretch, uv.y);

	float distance_to_center = length(portal_uv);
	float angle = atan(portal_uv.y, portal_uv.x);

	vec2 warped_uv = portal_uv;

	warped_uv += 0.035 * vec2(
		sin(angle * 3.0 - t * 1.3 + distance_to_center * 10.0),
		cos(angle * 4.0 + t * 1.1 + distance_to_center * 9.0)
	);

	float warped_distance = length(warped_uv);
	float warped_angle = atan(warped_uv.y, warped_uv.x);

	float swirl = sin(warped_angle * 5.0 - t * 2.0 + warped_distance * 14.0) * 0.5 + 0.5;
	float ripple = sin(warped_distance * 30.0 - t * 4.0) * 0.5 + 0.5;
	float turbulence = sin(warped_angle * 7.0 + t * 1.5 - warped_distance * 18.0) * 0.5 + 0.5;

	float outer_ring = Ring(warped_distance, 0.56 + sin(t * 1.2) * 0.015, 0.055);
	float middle_ring_01 = Ring(warped_distance, 0.42 + sin(t * 1.6 + 1.2) * 0.012, 0.040);
	float middle_ring_02 = Ring(warped_distance, 0.30 + sin(t * 1.8 + 2.1) * 0.010, 0.035);
	float inner_ring = Ring(warped_distance, 0.18 + sin(t * 2.0 + 0.8) * 0.008, 0.030);

	float vortex = 1.0 - smoothstep(0.02, 0.45, warped_distance);
	vortex *= mix(swirl, ripple, 0.5);

	float soft_glow = 1.0 - smoothstep(0.20, 0.75, warped_distance);
	soft_glow *= 0.35;

	float ring_mask = outer_ring * (0.75 + 0.25 * swirl);
	ring_mask += middle_ring_01 * (0.65 + 0.35 * ripple);
	ring_mask += middle_ring_02 * (0.60 + 0.40 * turbulence);
	ring_mask += inner_ring * (0.60 + 0.40 * swirl);

	float portal_mask = ring_mask + vortex * 0.65 + soft_glow * 0.35;
	portal_mask = clamp(portal_mask, 0.0, 1.0);

	vec3 color_mix = mix(outer_color.rgb, middle_color.rgb, swirl);
	color_mix = mix(color_mix, inner_color.rgb, ripple * 0.5);

	vec3 final_color = color_mix * portal_mask * intensity;

	COLOR = vec4(final_color, portal_mask);
}