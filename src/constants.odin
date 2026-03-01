package main

import "core:math/linalg"

import sdl "vendor:sdl3"

ASSETS_DIR  :: "assets"

// HD  - 720p  - 1280 x 720
// FHD - 1080p - 1920 x 1080
// QHD - 2k    - 2560 x 1440 (Ultra Wide)
// UHD - 4k    - 3840 x 2160 (Consumer Grade)
// DCI - 4k    - 4096 x 2160 (Digital Cinema, Wider)
SCREEN_SIZE   :: [2]i32{1280, 720}

MAX_FPS          :: f64(60)
FIXED_DELTA_TIME :: 1 / MAX_FPS
MAX_FRAME_SKIP   :: 5

//  60 -  75 for small screens
//  90 - 100 for medium
// 100 - 120 for large screens
FOV              :: 60
EYE_HEIGHT       :: 1
CAM_MOVE_SPEED   :: 5
LOOK_SENSITIVITY :: 0.5

WHITE :: sdl.FColor{1, 1, 1, 1}

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Mat2 :: matrix[2, 2]f32
Mat3 :: matrix[3, 3]f32
Mat4 :: matrix[4, 4]f32

Quat :: quaternion128

Forward :[3]f32: {0, 0, 1}

ROTATION_SPEED :: f32(90) * linalg.RAD_PER_DEG // linalg.to_radians(f32(90))