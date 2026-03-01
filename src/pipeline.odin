package main

import sdl "vendor:sdl3"

setup_text_pipeline :: proc() {
	vert_shader := load_shader("font.vert")
	frag_shader := load_shader("font.frag")

	g.text_pipeline = sdl.CreateGPUGraphicsPipeline(
		g.gpu,
		{
			fragment_shader = frag_shader,
			vertex_shader = vert_shader,
			primitive_type = .TRIANGLESTRIP,
			rasterizer_state = sdl.GPURasterizerState{
				cull_mode    = .BACK,
			},
			target_info = {
				num_color_targets = 1,
				color_target_descriptions = &(sdl.GPUColorTargetDescription {
					format = g.swapchain_texture_format,
					blend_state                 = (sdl.GPUColorTargetBlendState){
						enable_blend            = true,
						alpha_blend_op          = sdl.GPUBlendOp.ADD,
						color_blend_op          = sdl.GPUBlendOp.ADD,
						color_write_mask        = {.R, .G, .B},
						enable_color_write_mask = true,
						src_color_blendfactor   = sdl.GPUBlendFactor.ONE,
						src_alpha_blendfactor   = sdl.GPUBlendFactor.ONE,
						dst_color_blendfactor   = sdl.GPUBlendFactor.ONE_MINUS_SRC_ALPHA,
						dst_alpha_blendfactor   = sdl.GPUBlendFactor.ONE_MINUS_SRC_ALPHA,
					},
				}),
			},
		},
	)

	sdl.ReleaseGPUShader(g.gpu, vert_shader)
	sdl.ReleaseGPUShader(g.gpu, frag_shader)
}
