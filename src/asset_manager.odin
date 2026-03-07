package main

import "core:os"
import "core:log"
import "core:strings"

import "core:encoding/json"
import "core:path/filepath"

import sdl "vendor:sdl3"
import img "vendor:sdl3/image"

load_shader_info :: proc(shaderfile: string) -> Shader_Info {
	json_filename := strings.concatenate({shaderfile, ".json"}, context.temp_allocator)
	json_data, err := os.read_entire_file_from_path(json_filename, context.temp_allocator); assert(err == nil)

	result : Shader_Info
	unmarshal_err    := json.unmarshal(json_data, &result, allocator = context.temp_allocator); assert(unmarshal_err == nil)

	return result
}

load_shader :: proc(shaderfile: string) -> ^sdl.GPUShader {
	shaderfile_path, err := filepath.join({get_assets_dir(), "shaders", "out", shaderfile}, context.temp_allocator); assert(err == nil)

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
	shader_code, file_err := os.read_entire_file_from_path(filename, context.temp_allocator); assert(file_err == nil)
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
	msdf_json_file, err := filepath.join({get_assets_dir(), "fonts", msdf_json_file}, context.temp_allocator); assert(err == nil)

	file_data, file_err := os.read_entire_file_from_path(msdf_json_file, context.temp_allocator); assert(file_err == nil)

	msdf_data : MSDF_Data
	unmarshal_err := json.unmarshal(file_data, &msdf_data); assert(unmarshal_err == nil)

	msdf_data.glyphs_lut = make(map[i32]Glyph, len(msdf_data.glyphs))

	for glyph in msdf_data.glyphs {
		msdf_data.glyphs_lut[glyph.unicode] = glyph
	}

	msdf_data.unit_range = msdf_data.atlas.distanceRange / Vec2{msdf_data.atlas.width, msdf_data.atlas.height}

	return msdf_data;
}

load_font_msdf_file :: proc(gpu: ^sdl.GPUDevice, copy_pass: ^sdl.GPUCopyPass, msdf_file: string) -> ^sdl.GPUTexture {
	w, h: i32

	msdf_path, err := filepath.join({get_assets_dir(), "fonts", msdf_file}, context.temp_allocator); assert(err == nil)
	msdf_file := strings.clone_to_cstring(msdf_path, context.temp_allocator)

	return img.LoadGPUTexture(gpu, copy_pass, msdf_file, &w, &h)
}

get_assets_dir :: proc() -> string {
	executable_dir, err := os.get_executable_directory(context.temp_allocator); assert(err == nil)
	assets_dir, path_err  := filepath.join({executable_dir, "..", "Resources", "assets" }, context.temp_allocator); assert(path_err == nil)

	if os.exists(assets_dir) do return assets_dir

	return ASSETS_DIR
}
