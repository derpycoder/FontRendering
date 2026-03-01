package main

import os "core:os/os2"

import "core:strings"
import "core:slice"

import "core:path/filepath"

import "core:log"

SHADERCROSS :: "cli/shadercross/bin/shadercross"

main :: proc() {
	context.logger = log.create_console_logger()

	files, err := os.read_all_directory_by_path("assets/shaders/src", context.temp_allocator)
	if err != nil {
		log.errorf("Error reading shader sources: {}", err)
		os.exit(1)
	}
	for file in files {
		shadercross(file, "metal", "HLSL",   "MSL")
		shadercross(file,  "spv" , "HLSL", "SPIRV")
		shadercross(file,  "dxil", "HLSL",  "DXIL")
		shadercross(file,  "json", "HLSL",  "JSON")
	}

	// TODO: Disable compilation in debug build
	for file in files {
		compile_msl(file)
	}
}

compile_msl :: proc(file: os.File_Info) {
	basename := filepath.stem(file.name)
	src_file := filepath.join({"assets/shaders/out", strings.concatenate({basename, ".metal"   })}, context.temp_allocator)
	air_file := filepath.join({"assets/shaders/out", strings.concatenate({basename, ".air"     })}, context.temp_allocator)
	lib_file := filepath.join({"assets/shaders/out", strings.concatenate({basename, ".metallib"})}, context.temp_allocator)

	// TODO: Disable source map in Prod build 
	// -g for including the shader code in the binary for debugin in Metal debugger.
	run_arr({"xcrun", "metal", "-x", "metal", "-c", src_file, "-o", air_file, "-g"})
	run_arr({"xcrun", "metal",                      air_file, "-o", lib_file})
}

shadercross :: proc(file: os.File_Info, format: string, src_format: string, dest_format: string) {
	basename := filepath.stem(file.name)
	outfile  := filepath.join({"assets/shaders/out", strings.concatenate({basename, ".", format})}, context.temp_allocator)

	run_arr({SHADERCROSS, "-s", src_format, "-d", dest_format, file.fullpath, "-o", outfile})
}

run_arr  :: proc(cmd: []string) {
	log.infof("Running: {}", cmd)
	code, err := exec(cmd)

	if err != nil {
		log.errorf("Error executing process: {}", err)
		os.exit(1)
	}

	if code != 0 {
		log.errorf("Process exited with non zero code: {}", code)
		os.exit(1)
	}
}

exec :: proc(cmd: []string) -> (code: int, error: os.Error) {
	process := os.process_start({
									command = cmd      ,
									stdin   = os.stdin ,
									stdout  = os.stdout,
									stderr  = os.stderr,
								})      or_return

	state   := os.process_wait(process) or_return
	os.process_close          (process) or_return

	return state.exit_code, nil
}
