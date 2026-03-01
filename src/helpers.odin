package main

import "base:runtime"

import "core:log"

import sdl "vendor:sdl3"

sdl_log :: proc "c" (userdata: rawptr, category: sdl.LogCategory, priority: sdl.LogPriority, message: cstring) {
	context_ptr := cast(^runtime.Context)userdata
	context      = context_ptr^

	level: log.Level

	switch priority {
		case .INVALID,
			 .TRACE  ,
			 .VERBOSE,
			 .DEBUG   : level = .Debug
		case .INFO    : level = .Info
		case .WARN    : level = .Warning
		case .ERROR   : level = .Error
		case .CRITICAL: level = .Fatal
	}

	log.logf(level, "SDL {}: {}", category, message)
}
