// Cone Visibility Mask Shader - DreadConeRefactored
//
// Creates Darkwood-style visibility cone effect using hybrid Light2D + shader approach.
// Everything outside the cone is darkened to simulate tunnel vision.
// This shader creates a dark overlay with transparency in the cone area.

shader_type canvas_item;

uniform vec2 cone_origin = vec2(0.5, 0.5);  // Center point (screen space 0-1)
uniform vec2 cone_direction = vec2(0.0, -1.0);  // Direction vector (normalized)
uniform float cone_angle = 1.74533;  // Cone angle in radians (100 degrees default)
uniform float cone_range = 400.0;  // Cone range in pixels
uniform float edge_softness : hint_range(0.0, 1.0) = 0.15;  // Cone edge blur
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;  // Edge darkening
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);  // Vignette color

void fragment() {
	// Get pixel position in UV space (0-1)
	vec2 uv = UV;

	// Calculate vector from cone origin to pixel
	vec2 to_pixel = uv - cone_origin;
	float dist_to_origin = length(to_pixel);

	// Normalize direction to pixel
	vec2 pixel_dir = normalize(to_pixel);

	// Calculate angle between cone direction and pixel direction
	float cos_angle = dot(cone_direction, pixel_dir);
	float angle_rad = acos(clamp(cos_angle, -1.0, 1.0));

	// Calculate half cone angle
	float half_angle = cone_angle / 2.0;

	// Determine if pixel is inside cone with soft edges
	float soft_edge_range = edge_softness * half_angle;
	float inside_cone = 1.0 - smoothstep(half_angle - soft_edge_range, half_angle + soft_edge_range, angle_rad);

	// Calculate distance-based falloff
	float max_dist = cone_range / max(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y);
	float distance_falloff = 1.0 - smoothstep(0.0, max_dist, dist_to_origin);
	distance_falloff = clamp(distance_falloff, 0.0, 1.0);

	// Calculate vignette (distance-based darkening)
	float vignette = 1.0 - (dist_to_origin * vignette_strength);
	vignette = clamp(vignette, 0.0, 1.0);

	// Combine cone mask with distance falloff and vignette
	float visibility = inside_cone * distance_falloff * vignette;

	// Output as darkening overlay using vignette color
	// Inside cone = low alpha (transparent), Outside cone = high alpha (dark)
	float darkness = 1.0 - visibility;
	COLOR = vec4(vignette_color.rgb, darkness * vignette_color.a);
}
