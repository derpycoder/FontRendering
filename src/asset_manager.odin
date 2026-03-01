package main

import "core:os"
import os2 "core:os/os2"
import "core:log"
import "core:strings"

import "core:encoding/json"
import "core:path/filepath"

import sdl "vendor:sdl3"
import img "vendor:sdl3/image"

load_shader_info :: proc(shaderfile: string) -> Shader_Info {
	json_filename := strings.concatenate({shaderfile, ".json"}, context.temp_allocator)
	json_data, ok := os.read_entire_file_from_filename(json_filename, context.temp_allocator); assert(ok)

	result : Shader_Info
	err    := json.unmarshal(json_data, &result, allocator = context.temp_allocator); assert(err == nil)

	return result
}

load_shader :: proc(shaderfile: string) -> ^sdl.GPUShader {
	shaderfile_path := filepath.join({get_assets_dir(), "shaders", "out", shaderfile}, context.temp_allocator)

	stage: sdl.GPUShaderStage

	switch filepath.ext(shaderfile_path) {
		case ".vert":
			stage = .VERTEX
		case ".frag":
			stage = .FRAGMENT
	}

	format     : sdl.GPUShaderFormatFlag
	format_ext : string
	entrypoint : cstring = "main"

	supported_formats := sdl.GetGPUShaderFormats(g.gpu)
	if .SPIRV       in supported_formats {
		format     = .SPIRV
		format_ext = ".spv"
	} else if .METALLIB  in supported_formats {
		format     = .METALLIB
		format_ext = ".metallib"
		entrypoint = "main0"
	} else if .MSL  in supported_formats {
		format     = .MSL
		format_ext = ".metal"
		entrypoint = "main0"
	} else if .DXIL in supported_formats {
		format     = .DXIL
		format_ext = ".dxil"
	} else {
		log.panicf("No supported shader format: {}", supported_formats)
	}

	filename        := strings.concatenate({shaderfile_path, format_ext}, context.temp_allocator)
	shader_code, ok := os.read_entire_file_from_filename(filename, context.temp_allocator); assert(ok)
	shader_info     := load_shader_info(shaderfile_path)

	return sdl.CreateGPUShader(
		g.gpu,
		{
			code_size            = len(shader_code),
			code                 = raw_data(shader_code),
			entrypoint           = entrypoint,
			format               = {format},
			stage                = stage,
			num_samplers         = shader_info.samplers,
			num_uniform_buffers  = shader_info.uniform_buffers,
			num_storage_buffers  = shader_info.storage_buffers,
			num_storage_textures = shader_info.storage_textures,
		},
	)
}

load_font_json_file :: proc(msdf_json_file: string) -> MSDF_Data {
	msdf_json_file := filepath.join({get_assets_dir(), "fonts", msdf_json_file}, context.temp_allocator)

	file_data, ok := os.read_entire_file_from_filename(msdf_json_file, context.temp_allocator); assert(ok)

	msdf_data : MSDF_Data
	err := json.unmarshal(file_data, &msdf_data); assert(err == nil)

	msdf_data.glyphs_lut = make(map[i32]Glyph, len(msdf_data.glyphs))

	for glyph in msdf_data.glyphs {
		msdf_data.glyphs_lut[glyph.unicode] = glyph
	}

	msdf_data.unit_range = msdf_data.atlas.distanceRange / Vec2{msdf_data.atlas.width, msdf_data.atlas.height}

	return msdf_data;
}

load_font_msdf_file :: proc(gpu: ^sdl.GPUDevice, copy_pass: ^sdl.GPUCopyPass, msdf_file: string) -> ^sdl.GPUTexture {
	w, h: i32

	msdf_path := filepath.join({get_assets_dir(), "fonts", msdf_file}, context.temp_allocator)
	msdf_file := strings.clone_to_cstring(msdf_path, context.temp_allocator)

	return img.LoadGPUTexture(gpu, copy_pass, msdf_file, &w, &h)
}

get_assets_dir :: proc() -> string {
	executable_dir, err := os2.get_executable_directory(context.temp_allocator); assert(err == nil)
	contents_dir  := filepath.join({executable_dir, ".."       })
	resources_dir := filepath.join({  contents_dir, "Resources"})
	assets_dir    := filepath.join({ resources_dir, "assets"   })

	if os.exists(assets_dir) do return filepath.clean(assets_dir)

	return ASSETS_DIR
}
