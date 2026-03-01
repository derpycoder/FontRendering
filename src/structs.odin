package main

import sdl "vendor:sdl3"

Global_State :: struct {
	gpu     : ^sdl.GPUDevice,
	window  : ^sdl.Window,

	default_sampler : ^sdl.GPUSampler,
	text_pipeline   : ^sdl.GPUGraphicsPipeline,
	
	depth_texture           : ^sdl.GPUTexture,
	depth_texture_format    :  sdl.GPUTextureFormat,
	swapchain_texture_format:  sdl.GPUTextureFormat,

	key_pressed: #sparse [sdl.Scancode]bool, // Wastes lots of spaces, as the enum list has gaps, maybe use Hashmap?
	mouse_move : Vec2,

	using game: Game_State
}

Mesh :: struct {
	vertex_buf : ^sdl.GPUBuffer,
	index_buf  : ^sdl.GPUBuffer,
	num_indices:  u32,
}

UBO_Vert_Global :: struct #packed {
	view_projection_mat: Mat4,
}

UBO_Font_Global :: struct {
	fill_color     : Vec4,
	stroke_color   : Vec4,

	stroke_blur    : f32,

	rounded_fill   : f32,
	rounded_stroke : f32,

	stroke_width_relative : f32,
	stroke_width_absolute : f32,

	in_bias    : f32,
	out_bias   : f32,

	threshold  : f32,

	unit_range : Vec2,
	aemrange   : Vec2,
}

SSBO_Font_Local :: struct {
	model_mat  : Mat4,
	uv_rect    : Vec4,
	plane_rect : Vec4,
}

Shader_Info :: struct {
	samplers        : u32,
	storage_textures: u32,
	storage_buffers : u32,
	uniform_buffers : u32,
}

MSDF_Data :: struct {
	name       : string,
	atlas      : Atlas,
	metrics    : Metrics,
	glyphs     : []Glyph,
	glyphs_lut : map[i32]Glyph,
	unit_range : Vec2,
}

Bounds :: struct {
	left    : f32,
	bottom  : f32,
	right   : f32,
	top     : f32
}

Atlas :: struct {
    type    : string,
    size    : f32,
    width   : f32,
    height  : f32,
    yOrigin : string,
    distanceRange       : f32,
    distanceRangeMiddle : f32,
}

Glyph :: struct {
	unicode     : i32,
	advance     : f32,
	planeBounds : Bounds,
	atlasBounds : Bounds,
}

Metrics :: struct {
	emSize      : f32,
	lineHeight  : f32,
	ascender    : f32,
	descender   : f32,
	underlineY  : f32,
	underlineThickness : f32,
}
