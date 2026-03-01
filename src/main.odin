package main

import "base:runtime"

import "core:log"
import "core:fmt"

import "core:math/linalg"

import sdl "vendor:sdl3"

import "shared:tracker"
import "shared:afmt"

import im        "shared:imgui"
import im_sdl    "shared:imgui/imgui_impl_sdl3"
import im_sdlgpu "shared:imgui/imgui_impl_sdlgpu3"

USE_TRACKING_ALLOCATOR :: #config(USE_TRACKING_ALLOCATOR, true)

g: Global_State

init_sdl :: proc() {
	@static sdl_log_context: runtime.Context
	sdl_log_context = context
	sdl_log_context.logger.options -= {.Short_File_Path, .Line, .Procedure}
	
	sdl.SetLogPriorities    (.VERBOSE)
	sdl.SetLogOutputFunction(sdl_log, &sdl_log_context)

	ok := sdl.Init({.VIDEO}); assert(ok)

	g.window = sdl.CreateWindow(
		"SDL3 3D | FPS: 60.00 (0.02 ms) | Fixed Updates: 60.00 Hz",
		SCREEN_SIZE.x,
		SCREEN_SIZE.y,
		{},
	); assert(g.window != nil)
	ok = sdl.RaiseWindow(g.window); assert(ok)

	g.gpu = sdl.CreateGPUDevice({.METALLIB, .MSL, .SPIRV, .DXIL}, true, nil); assert(g.gpu != nil)

	ok = sdl.ClaimWindowForGPUDevice(g.gpu, g.window); assert(ok)

	ok = sdl.SetGPUSwapchainParameters(g.gpu, g.window, .SDR_LINEAR, .IMMEDIATE); assert(ok)

	g.swapchain_texture_format = sdl.GetGPUSwapchainTextureFormat(g.gpu, g.window)

	// For MacOS .D32_FLOAT
	g.depth_texture_format = sdl.GPUTextureFormat.D16_UNORM
	try_depth_texture_format(.D32_FLOAT)
	try_depth_texture_format(.D24_UNORM)

	g.depth_texture = sdl.CreateGPUTexture(
		g.gpu,
		{
			type                 = .D2,
			format               = g.depth_texture_format,
			usage                = {.DEPTH_STENCIL_TARGET},
			width                = u32(SCREEN_SIZE.x),
			height               = u32(SCREEN_SIZE.y),
			layer_count_or_depth = 1,
			num_levels           = 1,
		},
	)

	try_depth_texture_format :: proc(format: sdl.GPUTextureFormat) {
		if sdl.GPUTextureSupportsFormat(g.gpu, format, .D2, {.DEPTH_STENCIL_TARGET}) {
			g.depth_texture_format = format
		}
	}

	_ = sdl.SetWindowRelativeMouseMode(g.window, true)
}

init_imgui :: proc() {
	im.CHECKVERSION()
	im.CreateContext()

	im_sdl.InitForSDLGPU(g.window)
	im_sdlgpu.Init(&{
		Device            = g.gpu,
		ColorTargetFormat = g.swapchain_texture_format,
	})

	style := im.GetStyle()
	catppuccin_mocha_theme(style)

	for &color in style.Colors {
		color.rgb = linalg.pow(color.rgb, 2.2) // Gamma Correction for Imgui
	}
}

main :: proc() {
	context.logger = log.create_console_logger()

	init_sdl()
	init_imgui()
	game_init()

	when USE_TRACKING_ALLOCATOR {
		t := tracker.init_tracker()
		context.allocator = tracker.tracking_allocator(&t)
		defer tracker.print_and_destroy_tracker(&t)
	}

	ok: bool
	text: cstring

	prev_counter := sdl.GetPerformanceCounter()

	delta_ticks, curr_counter: u64
	updates, fixed_updates   : int
	accumulator, dt, alpha   : f64 = 0, 0, 0

	frame_count     : u16
	time_accumulator: f64
	updates_per_sec : f64

	fps_smoothed, current_fps: f64 = 60, 60

	free_all(context.temp_allocator)

	ui_input_mode := !sdl.GetWindowRelativeMouseMode(g.window)
	style := im.GetStyle()
	if !ui_input_mode {
	    style.Alpha = 0.01
	} else {
		style.Alpha = 1
	}

	main_loop: for {
		free_all(context.temp_allocator)
		g.mouse_move = {}

		curr_counter = sdl.GetPerformanceCounter()
		delta_ticks = curr_counter - prev_counter
		prev_counter = curr_counter

		dt = f64(delta_ticks) / f64(sdl.GetPerformanceFrequency())

		// Process Events
		ev: sdl.Event
		for sdl.PollEvent(&ev) {
			if ui_input_mode do im_sdl.ProcessEvent(&ev)

			#partial switch ev.type {
				case .QUIT:
					break main_loop
				case .KEY_DOWN:
					if ev.key.scancode == .ESCAPE do break main_loop

					if ev.key.scancode == .RETURN {
						ui_input_mode = !ui_input_mode
						_ = sdl.SetWindowRelativeMouseMode(g.window, !ui_input_mode)

						style := im.GetStyle()
						if !ui_input_mode {
						    style.Alpha = 0.01
						} else {
							style.Alpha = 1
						}
					}

					if !ui_input_mode do g.key_pressed[ev.key.scancode] = true
				case .KEY_UP:
					g.key_pressed[ev.key.scancode] = false
				case .MOUSE_MOTION:
					if !ui_input_mode do g.mouse_move += {ev.motion.xrel, ev.motion.yrel}
			}
		}

		im_sdlgpu.NewFrame()
		im_sdl.NewFrame()
		im.NewFrame()

		accumulator += dt
		updates = 0

		// ------ Fixed Update Loop ------
		for ; accumulator >= FIXED_DELTA_TIME && updates < MAX_FRAME_SKIP; accumulator -= FIXED_DELTA_TIME {
			// fixed_update()
			updates += 1
			fixed_updates += 1
		}
		// ------ Fixed Update Loop ------

		// Handle slow performance by resetting accumulator to avoid "spiral of death"
		if updates >= MAX_FRAME_SKIP {
			accumulator = 0.0
		}

		alpha = accumulator / FIXED_DELTA_TIME

		game_update(dt, alpha)

		// ------ Dear ImGUI Data Render ------
		im.Render()
		im_draw_data := im.GetDrawData()
		// ------ Dear ImGUI Data Render ------

		// Acquire command buffer
		cmd_buf := sdl.AcquireGPUCommandBuffer(g.gpu)

		// Acquire swapchain texture
		swapchain_tex: ^sdl.GPUTexture
		ok = sdl.WaitAndAcquireGPUSwapchainTexture(
			cmd_buf ,
			g.window,
			&swapchain_tex,
			nil,
			nil,
		); assert(ok)

		if swapchain_tex != nil {
			game_render(cmd_buf, swapchain_tex)

			// More render passes

			// ------ Dear ImGUI Render ------
			if im_draw_data.DisplaySize.x > 0 && im_draw_data.DisplaySize.y > 0 {
				im_sdlgpu.PrepareDrawData(im_draw_data, cmd_buf)
				im_color_target := sdl.GPUColorTargetInfo {
					texture  = swapchain_tex,
					load_op  = .LOAD,
					store_op = .STORE,
				}
				im_render_pass  := sdl.BeginGPURenderPass(cmd_buf, &im_color_target, 1, nil)
				im_sdlgpu.RenderDrawData(im_draw_data, cmd_buf, im_render_pass)
				sdl.EndGPURenderPass(im_render_pass)
			}
			// ------ Dear ImGUI Render ------
		}

		// Submit command buffer
		ok = sdl.SubmitGPUCommandBuffer(cmd_buf); assert(ok)

		// ------ FPS Counter ------
		frame_count += 1
		time_accumulator += dt
		if time_accumulator >= 1 {
			current_fps = f64(frame_count) / time_accumulator
			fps_smoothed = 0.9 * fps_smoothed + 0.1 * current_fps
			updates_per_sec = f64(fixed_updates) / time_accumulator

			text = fmt.caprintf(
				"SDL3 3D | FPS: %.2f (%.4f ms) | Fixed Updates: %.2f Hz",
				current_fps,
				dt,
				updates_per_sec,
			)
			sdl.SetWindowTitle(g.window, text)

			frame_count = 0
			fixed_updates = 0
			time_accumulator = 0
		}
		// ------ FPS Counter ------
	}
}
