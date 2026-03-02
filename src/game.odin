package main

import "core:slice"

import "core:math"
import "core:math/linalg"

import "core:fmt"
import "core:log"

import "core:c"
import "core:mem"
import "core:strings"

import sdl "vendor:sdl3"

import im "shared:imgui"

Game_State :: struct {
	camera      : struct {
		position: Vec3,
		target  : Vec3,
	},
	look       : struct {
		yaw  : f32, // Horizontal Rotation (Around Y Axis)
		pitch: f32, // Vertical   Rotation (Around X Axis)
	},

	ambient_light_color: Vec3,

	font_msdf: ^sdl.GPUTexture,
	msdf_data: MSDF_Data,

	text    : string,
	text_buf: [4_500_000]u8, // 4_500_000

	model_mat: Mat4,

	old_string: string,
	new_string: string,

	ssbo    : [dynamic]SSBO_Font_Local,
	ssbo_buf: ^sdl.GPUBuffer,

	char_count: u32,

	builder: strings.Builder
}

game_init :: proc() {
	setup_text_pipeline()

	copy_cmd_buf := sdl.AcquireGPUCommandBuffer(g.gpu)
	copy_pass := sdl.BeginGPUCopyPass(copy_cmd_buf)

	g.default_sampler = sdl.CreateGPUSampler(g.gpu, {
		min_filter = .LINEAR,
		mag_filter = .LINEAR,
	})

	g.font_msdf = load_font_msdf_file(g.gpu, copy_pass, "FiraCodeNerdFont-Regular.png")
	g.msdf_data = load_font_json_file("FiraCodeNerdFont-Regular.json")

	sdl.EndGPUCopyPass(copy_pass)
	ok := sdl.SubmitGPUCommandBuffer(copy_cmd_buf); assert(ok)

	g.camera = {
		position = {0, EYE_HEIGHT, 3}, // Stays 3 meters back from Origin
		target   = {0, EYE_HEIGHT, 0}, // Looks at origin
	}

	g.ambient_light_color = {0.005, 0.005, 0.016}

	g.text = "Derpy Coder"
	copy(g.text_buf[:], g.text)

	g.model_mat = linalg.MATRIX4F32_IDENTITY
	g.old_string = ""

	g.ssbo = make([dynamic]SSBO_Font_Local, context.allocator)

	g.builder = strings.builder_make(context.allocator)
	strings.write_string(&g.builder, "Made with ")
	strings.write_rune(&g.builder, 0xe23a)
    strings.write_string(&g.builder, " Derpy Coder")

    g.new_string = strings.to_string(g.builder)
}

game_update :: proc(dt: f64, alpha: f64) {
	// if im.Begin("Inspector") {
	// 	im.ColorEdit3("Ambient Color", &g.ambient_light_color, {.Float})

	// 	im.SeparatorText("Names")
	// 	if im.InputText("Text: ", cstring(&g.text_buf[0]), 4_500_000) {
	// 		g.text = string(cstring(&g.text_buf[0]))

	// 		strings.builder_reset(&g.builder)
	// 	    strings.builder_destroy(&g.builder)
	// 	    g.builder = strings.builder_make(context.allocator)
	// 	    strings.write_string(&g.builder, "Made with ")
	// 	    strings.write_rune(&g.builder, 0xe23a)
	// 	    strings.write_string(&g.builder, " by ")
	// 	    strings.write_string(&g.builder, g.text)

	// 	    g.new_string = strings.to_string(g.builder)
	// 	    // g.new_string = string(cstring(&g.text_buf[0]))

	// 	    // g.builder = strings.builder_from_bytes(g.text_buf[:])
	// 	    // g.new_string = strings.to_string(g.builder)
	// 	    // strings.builder_reset(&g.builder)
	// 	    // strings.builder_destroy(&g.builder)
	// 	}

	// }
	// im.End()

	update_camera(dt)
}

game_render :: proc(cmd_buf: ^sdl.GPUCommandBuffer, swapchain_tex: ^sdl.GPUTexture) {
	// ------ MVP Calculations ------
	proj_mat := linalg.matrix4_perspective_f32(
		linalg.to_radians(f32(FOV)),
		f32(SCREEN_SIZE.x) / f32(SCREEN_SIZE.y),
		0.0001,
		1000,
	)
	view_mat  := linalg.matrix4_look_at_f32(g.camera.position, g.camera.target, {0, 1, 0})
	// ------ MVP Calculations ------

	ubo_vert_global := UBO_Vert_Global {
		view_projection_mat = proj_mat * view_mat,
	}
	sdl.PushGPUVertexUniformData(cmd_buf, 0, &ubo_vert_global, size_of(ubo_vert_global))  // Uniform vert stuff available across all shaders like Global

	clear_color : sdl.FColor = 1
	clear_color.rgb          = g.ambient_light_color

	color_target := sdl.GPUColorTargetInfo {
		texture     = swapchain_tex,
		load_op     = .CLEAR,
		clear_color = clear_color,
		store_op    = .STORE,
	}
	depth_target_info := sdl.GPUDepthStencilTargetInfo {
		texture     = g.depth_texture,
		load_op     = .CLEAR,
		clear_depth = 1,
		store_op    = .DONT_CARE,
	}
	render_pass := sdl.BeginGPURenderPass(cmd_buf, &color_target, 1, &depth_target_info)

	text_mesh: Mesh

	copy_cmd_buf := sdl.AcquireGPUCommandBuffer(g.gpu)
	copy_pass := sdl.BeginGPUCopyPass(copy_cmd_buf)

	{
	    if g.new_string != g.old_string {
	    	cursor: f32
			y     : f32
	    	v, i  : u16

			width, height : f32 = g.msdf_data.atlas.width, g.msdf_data.atlas.height

			g.ssbo = make([dynamic]SSBO_Font_Local, context.allocator)
			g.char_count = 0

			count: u32

			for char in g.new_string {
				glyph := g.msdf_data.glyphs_lut[i32(char)]

				pl, pb, pr, pt : f32 = glyph.planeBounds.left, glyph.planeBounds.bottom, glyph.planeBounds.right, glyph.planeBounds.top
		        al, ab, ar, at : f32 = glyph.atlasBounds.left, glyph.atlasBounds.bottom, glyph.atlasBounds.right, glyph.atlasBounds.top

				model_mat  := linalg.matrix4_from_trs_f32({-1.6 + cursor, y, 0}, 0, 0.2)

				if count == 10_000 {
					count = 0

					y	+= g.msdf_data.metrics.lineHeight * 0.2
					cursor = 0
				}

				append(&g.ssbo, SSBO_Font_Local{
					model_mat  = model_mat,
					uv_rect    = {
						al / width,         // x offset
						1 - (at / height),  // y offset
						(ar - al) / width,  // width
						(at - ab) / height, // height
					},
					plane_rect = {
						pl,                 // x
						pb,                 // y
						pr - pl,            // width
						pt - pb,            // height
					}
				})
				g.char_count += 1; count += 1

				cursor += math.max(pr * 0.2 - pl * 0.2, glyph.advance * 0.2)
			}
			
		    ssbo_byte_size := g.char_count * size_of(SSBO_Font_Local)

		    sdl.ReleaseGPUBuffer(g.gpu, g.ssbo_buf)
			g.ssbo_buf = sdl.CreateGPUBuffer(g.gpu, {
				usage = {.GRAPHICS_STORAGE_READ},
				size  = u32(ssbo_byte_size),
			})
			transfer_buf := sdl.CreateGPUTransferBuffer(g.gpu, {
				usage = .UPLOAD,
				size  = u32(ssbo_byte_size),
			})
			transfer_mem := sdl.MapGPUTransferBuffer(g.gpu, transfer_buf, false)
			mem.copy(transfer_mem, raw_data(g.ssbo), int(ssbo_byte_size))

			copy_cmd_buf := sdl.AcquireGPUCommandBuffer(g.gpu)
			copy_pass    := sdl.BeginGPUCopyPass(copy_cmd_buf)
			sdl.UploadToGPUBuffer(copy_pass,
				{ transfer_buffer = transfer_buf },
				{ buffer          = g.ssbo_buf,
				  size            = u32(ssbo_byte_size) },
				false,
			)
			sdl.EndGPUCopyPass(copy_pass)
			ok := sdl.SubmitGPUCommandBuffer(copy_cmd_buf); assert(ok)

			sdl.ReleaseGPUTransferBuffer(g.gpu, transfer_buf)
			delete(g.ssbo)

			g.old_string = g.new_string
		}
	}

	sdl.EndGPUCopyPass(copy_pass)
	ok := sdl.SubmitGPUCommandBuffer(copy_cmd_buf); assert(ok)

	ubo_font_global := UBO_Font_Global {
		fill_color            = Vec4{0.515, 0.132, 0.296, 1},
		stroke_color          = Vec4{0.933, 0.784, 0.455, 1},
		stroke_blur           = 0.2,
		rounded_fill          = 0,
		rounded_stroke        = 0,
		stroke_width_relative = 0,
		stroke_width_absolute = 0,
		in_bias               = 0,
		out_bias              = 0.5,
		threshold             = 0.4,
		unit_range            = g.msdf_data.unit_range,
		aemrange              = Vec2{-0.04, +0.01},
	}
	sdl.PushGPUFragmentUniformData(cmd_buf, 0, &ubo_font_global, size_of(ubo_font_global))

	{
		sdl.BindGPUGraphicsPipeline(render_pass, g.text_pipeline)

		sdl.BindGPUVertexStorageBuffers(render_pass, 0, &g.ssbo_buf, 1)
		sdl.BindGPUFragmentSamplers(render_pass, 0, &(sdl.GPUTextureSamplerBinding{texture = g.font_msdf, sampler = g.default_sampler}), 1)

		sdl.DrawGPUPrimitives(render_pass, 4, g.char_count, 0, 0)
	}

	// End render pass
	sdl.EndGPURenderPass(render_pass)
}
