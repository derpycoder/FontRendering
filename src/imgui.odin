package main

import im "shared:imgui"
import im_sdl    "shared:imgui/imgui_impl_sdl3"
import im_sdlgpu "shared:imgui/imgui_impl_sdlgpu3"

// https://github.com/ocornut/imgui/issues/707#issuecomment-3592676777
catppuccin_mocha_theme :: proc(style: ^im.Style) {
    // Catppuccin Mocha Palette
    // --------------------------------------------------------
    base     := Vec4{0.117, 0.117, 0.172, 1.0} // #1e1e2e
    mantle   := Vec4{0.109, 0.109, 0.156, 1.0} // #181825
    surface0 := Vec4{0.200, 0.207, 0.286, 1.0} // #313244
    surface1 := Vec4{0.247, 0.254, 0.337, 1.0} // #3f4056
    surface2 := Vec4{0.290, 0.301, 0.388, 1.0} // #4a4d63
    overlay0 := Vec4{0.396, 0.403, 0.486, 1.0} // #65677c
    overlay2 := Vec4{0.576, 0.584, 0.654, 1.0} // #9399b2
    text     := Vec4{0.803, 0.815, 0.878, 1.0} // #cdd6f4
    subtext0 := Vec4{0.639, 0.658, 0.764, 1.0} // #a3a8c3
    mauve    := Vec4{0.796, 0.698, 0.972, 1.0} // #cba6f7
    peach    := Vec4{0.980, 0.709, 0.572, 1.0} // #fab387
    yellow   := Vec4{0.980, 0.913, 0.596, 1.0} // #f9e2af
    green    := Vec4{0.650, 0.890, 0.631, 1.0} // #a6e3a1
    teal     := Vec4{0.580, 0.886, 0.819, 1.0} // #94e2d5
    sapphire := Vec4{0.458, 0.784, 0.878, 1.0} // #74c7ec
    blue     := Vec4{0.533, 0.698, 0.976, 1.0} // #89b4fa
    lavender := Vec4{0.709, 0.764, 0.980, 1.0} // #b4befe

    // Main window and backgrounds
    style.Colors[im.Col.WindowBg]              = base
    style.Colors[im.Col.ChildBg]               = base
    style.Colors[im.Col.PopupBg]               = surface0
    style.Colors[im.Col.Border]                = surface1
    style.Colors[im.Col.BorderShadow]          = Vec4{0.0, 0.0, 0.0, 0.0}
    style.Colors[im.Col.FrameBg]               = surface0
    style.Colors[im.Col.FrameBgHovered]        = surface1
    style.Colors[im.Col.FrameBgActive]         = surface2
    style.Colors[im.Col.TitleBg]               = mantle
    style.Colors[im.Col.TitleBgActive]         = surface0
    style.Colors[im.Col.TitleBgCollapsed]      = mantle
    style.Colors[im.Col.MenuBarBg]             = mantle
    style.Colors[im.Col.ScrollbarBg]           = surface0
    style.Colors[im.Col.ScrollbarGrab]         = surface2
    style.Colors[im.Col.ScrollbarGrabHovered]  = overlay0
    style.Colors[im.Col.ScrollbarGrabActive]   = overlay2
    style.Colors[im.Col.CheckMark]             = green
    style.Colors[im.Col.SliderGrab]            = sapphire
    style.Colors[im.Col.SliderGrabActive]      = blue
    style.Colors[im.Col.Button]                = surface0
    style.Colors[im.Col.ButtonHovered]         = surface1
    style.Colors[im.Col.ButtonActive]          = surface2
    style.Colors[im.Col.Header]                = surface0
    style.Colors[im.Col.HeaderHovered]         = surface1
    style.Colors[im.Col.HeaderActive]          = surface2
    style.Colors[im.Col.Separator]             = surface1
    style.Colors[im.Col.SeparatorHovered]      = mauve
    style.Colors[im.Col.SeparatorActive]       = mauve
    style.Colors[im.Col.ResizeGrip]            = surface2
    style.Colors[im.Col.ResizeGripHovered]     = mauve
    style.Colors[im.Col.ResizeGripActive]      = mauve
    style.Colors[im.Col.Tab]                   = surface0
    style.Colors[im.Col.TabHovered]            = surface2
    style.Colors[im.Col.TabActive]             = surface1
    style.Colors[im.Col.TabUnfocused]          = surface0
    style.Colors[im.Col.TabUnfocusedActive]    = surface1
    style.Colors[im.Col.DockingPreview]        = sapphire
    style.Colors[im.Col.DockingEmptyBg]        = base
    style.Colors[im.Col.PlotLines]             = blue
    style.Colors[im.Col.PlotLinesHovered]      = peach
    style.Colors[im.Col.PlotHistogram]         = teal
    style.Colors[im.Col.PlotHistogramHovered]  = green
    style.Colors[im.Col.TableHeaderBg]         = surface0
    style.Colors[im.Col.TableBorderStrong]     = surface1
    style.Colors[im.Col.TableBorderLight]      = surface0
    style.Colors[im.Col.TableRowBg]            = Vec4{0.0, 0.0, 0.0, 0.0}
    style.Colors[im.Col.TableRowBgAlt]         = Vec4{1.0, 1.0, 1.0, 0.06}
    style.Colors[im.Col.TextSelectedBg]        = surface2
    style.Colors[im.Col.DragDropTarget]        = yellow
    style.Colors[im.Col.NavHighlight]          = lavender
    style.Colors[im.Col.NavWindowingHighlight] = Vec4{1.0, 1.0, 1.0, 0.7}
    style.Colors[im.Col.NavWindowingDimBg]     = Vec4{0.8, 0.8, 0.8, 0.2}
    style.Colors[im.Col.ModalWindowDimBg]      = Vec4{0.0, 0.0, 0.0, 0.35}
    style.Colors[im.Col.Text]                  = text
    style.Colors[im.Col.TextDisabled]          = subtext0

    // Rounded corners
    style.WindowRounding    = 6.0
    style.ChildRounding     = 6.0
    style.FrameRounding     = 4.0
    style.PopupRounding     = 4.0
    style.ScrollbarRounding = 9.0
    style.GrabRounding      = 4.0
    style.TabRounding       = 4.0

    // Padding and spacing
    style.WindowPadding     = Vec2{8.0, 8.0}
    style.FramePadding      = Vec2{5.0, 3.0}
    style.ItemSpacing       = Vec2{8.0, 4.0}
    style.ItemInnerSpacing  = Vec2{4.0, 4.0}
    style.IndentSpacing     = 21.0
    style.ScrollbarSize     = 14.0
    style.GrabMinSize       = 10.0

    // Borders
    style.WindowBorderSize  = 1.0
    style.ChildBorderSize   = 1.0
    style.PopupBorderSize   = 1.0
    style.FrameBorderSize   = 0.0
    style.TabBorderSize     = 0.0
}
