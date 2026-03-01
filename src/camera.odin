package main

import "core:math"
import "core:math/linalg"

update_camera :: proc(dt: f64) {
	// Get move input
	move_input: Vec3

	// Back and Forth
	if      g.key_pressed[.W] do move_input.y =  1
	else if g.key_pressed[.S] do move_input.y = -1

	// Left and Right - Horizontal
	if      g.key_pressed[.A] do move_input.x = -1
	else if g.key_pressed[.D] do move_input.x =  1

	// Up and Down
	if      g.key_pressed[.E] do move_input.z =  1
	else if g.key_pressed[.Q] do move_input.z = -1

	// Get look input
	look_input := g.mouse_move * LOOK_SENSITIVITY

	// Update look values
	g.look.yaw    = math.wrap (g.look.yaw   - look_input.x,   360  )
	g.look.pitch  = math.clamp(g.look.pitch - look_input.y, -89, 89) // To avoid Euler angle issue, maybe use Quaternion later

	// Calculate forward / right vectors
	look_mat := linalg.matrix3_from_yaw_pitch_roll_f32(linalg.to_radians(g.look.yaw), linalg.to_radians(g.look.pitch), 0)
	forward  := look_mat * Vec3{0,  0, -1}
	right    := look_mat * Vec3{1,  0,  0}
	up       := look_mat * Vec3{0,  1,  0}

	// Calculate movement direction
	move_dir  := forward * move_input.y + right * move_input.x + up * move_input.z
	// move_dir.y = 0 // If we don't want the camera to fly off

	// Calculate motion
	motion   := linalg.normalize0(move_dir) * CAM_MOVE_SPEED * f32(dt)

	// Apply motion to camera position
	g.camera.position += motion

	// Update camera target
	g.camera.target    = g.camera.position + forward
}