@tool
extends EditorScript

## Utility script to generate cone-shaped textures for flashlights.
## Run this in the editor via File > Run to generate cone textures.
##
## Usage: Select this script in FileSystem, then File > Run

func _run() -> void:
	print("Generating cone texture...")

	var width: int = 512
	var height: int = 512

	# Create image with alpha channel
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)

	# Fill with cone shape (white triangle pointing up on black background)
	for y in range(height):
		for x in range(width):
			var color := Color.BLACK

			# Create cone shape pointing upward
			# Cone starts wide at bottom (y=height) and narrows to point at top (y=0)
			var normalized_y: float = float(y) / float(height)  # 0 at top, 1 at bottom
			var center_x: float = width / 2.0
			var cone_width_at_y: float = normalized_y * (width * 0.8)  # Cone width varies with Y

			# Check if pixel is inside cone
			var distance_from_center: float = abs(float(x) - center_x)
			if distance_from_center <= cone_width_at_y / 2.0:
				# Inside cone - make it white
				# Add soft falloff at edges
				var edge_distance: float = (cone_width_at_y / 2.0) - distance_from_center
				var edge_softness: float = 20.0
				var alpha: float = clampf(edge_distance / edge_softness, 0.0, 1.0)

				# Brighter at top (light source), dimmer at bottom
				var brightness: float = 1.0 - (normalized_y * 0.5)  # 1.0 at top, 0.5 at bottom

				color = Color(brightness, brightness, brightness, alpha)

			image.set_pixel(x, y, color)

	# Save as PNG
	var save_path := "res://resources/lighting/cone_texture_up.png"
	var err := image.save_png(save_path)

	if err == OK:
		print("✓ Cone texture saved to: ", save_path)
		print("  To use: Assign this texture to FlashlightData.light_texture")
		print("  Adjust texture_rotation in FlashlightData to orient the cone")
	else:
		push_error("Failed to save cone texture: ", err)
