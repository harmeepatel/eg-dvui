const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");
const fonts = @import("fonts");
const components = @import("components.zig");

const Rect = dvui.Rect;
const Size = dvui.Size;

const window_icon_png = @embedFile("assets/achal-logo.png");

pub const win_aspect_ratio: Rect = .{ .w = 16.0, .h = 10.0 };
pub const win_init_size: Size = .{ .w = win_aspect_ratio.w * 100, .h = win_aspect_ratio.h * 100 };
pub const win_min_size: Size = .{ .w = win_aspect_ratio.w * 30, .h = win_aspect_ratio.h * 30 };

pub const small_spacing = 8.0;
pub const medium_spacing = 16.0;
pub const large_spacing = 32.0;

pub const dvui_app: dvui.App = .{
    .config = .{
        .options = .{
            .size = win_init_size,
            .min_size = win_min_size,
            .title = "DVUI App Example",
            .icon = window_icon_png,
        },
    },
    .initFn = AppInit,
    .frameFn = AppFrame,
    .deinitFn = AppDeinit,
};

pub const main = dvui.App.main;
pub const panic = dvui.App.panic;
pub const std_options: std.Options = .{
    .logFn = dvui.App.logFn,
};

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_instance.allocator();

var orig_content_scale: f32 = 1.0;

// init app state
pub fn AppInit(win: *dvui.Window) !void {
    orig_content_scale = win.content_scale;

    try dvui.addFont("Cascadia_Mono_ExtraLight", fonts.Cascadia_Mono_Light, null);
    try dvui.addFont("Cascadia_Mono_Light", fonts.Cascadia_Mono_Light, null);
    try dvui.addFont("Cascadia_Mono_Regular", fonts.Cascadia_Mono_Regular, null);
    try dvui.addFont("Cascadia_Mono_Medium", fonts.Cascadia_Mono_Regular, null);
    try dvui.addFont("Cascadia_Mono_SemiBold", fonts.Cascadia_Mono_Regular, null);
    try dvui.addFont("Cascadia_Mono_Bold", fonts.Cascadia_Mono_Bold, null);

    if (false) {
        win.theme = switch (win.backend.preferredColorScheme() orelse .dark) {
            .light => dvui.Theme.builtin.adwaita_light,
            .dark => dvui.Theme.builtin.adwaita_dark,
        };
    }
}

// deinit app
pub fn AppDeinit() void {}

pub fn AppFrame() !dvui.App.Result {
    return frame();
}

// this is redrawn every frame
pub fn frame() !dvui.App.Result {

    // idk what this is
    var scaler = dvui.scale(@src(), .{ .scale = &dvui.currentWindow().content_scale, .pinch_zoom = .global }, .{ .rect = .cast(dvui.windowRect()) });
    scaler.deinit();

    // reset value for the background box for horizontal line
    var background_box = dvui.box(@src(), .{}, .{
        .expand = .both,
        .background = true,
        .color_fill = dvui.Color{ .r = 43, .g = 43, .b = 43 },
    });
    defer background_box.deinit();

    // menu
    {
        {
            var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{ .style = .window, .background = true, .expand = .horizontal, .padding = Rect.all(small_spacing) });
            defer hbox.deinit();

            var m = dvui.menu(@src(), .horizontal, .{});
            defer m.deinit();

            if (dvui.menuItemLabel(@src(), "File", .{ .submenu = true }, .{ .tag = "first-focusable" })) |r| {
                var fw = dvui.floatingMenu(@src(), .{ .from = r }, .{});
                defer fw.deinit();

                if (dvui.menuItemLabel(@src(), "Close Menu", .{}, .{ .expand = .horizontal }) != null) {
                    m.close();
                }

                if (dvui.backend.kind != .web) {
                    if (dvui.menuItemLabel(@src(), "Exit", .{}, .{ .expand = .horizontal }) != null) {
                        return .close;
                    }
                }
            }
        }

        {
            var pad = dvui.box(@src(), .{}, .{ .padding = Rect.all(small_spacing) });
            defer pad.deinit();

            var line = dvui.box(@src(), .{}, .{
                .background = true,
                .color_fill = dvui.Color.gray,
                .min_size_content = dvui.Size{ .w = dvui.windowRectPixels().w, .h = 1 },
            });
            defer line.deinit();
        }
    }

    // scrollable area below the menu
    var scroll = dvui.scrollArea(@src(), .{}, .{ .expand = .both, .style = .window });
    defer scroll.deinit();

    // padding for the area below menu
    var main_container = dvui.box(@src(), .{}, .{
        .padding = Rect.all(large_spacing),
        // .border = Rect.all(1.0),
        // .color_border = dvui.Color{ .r = 255, .g = 0, .b = 0 },
    });
    defer main_container.deinit();

    // flex two column form fields
    {
        // two column layout with half the window width
        var column_width = (dvui.windowRect().w / 2.0) - large_spacing;

        // change column direction when window size is less than half
        var container_dir: dvui.enums.Direction = .horizontal;
        if (dvui.windowRect().w < win_init_size.w / 2.0) {
            container_dir = .vertical;
            column_width = dvui.windowRect().w;
        }

        var container = dvui.box(@src(), .{ .dir = container_dir }, .{
            .expand = .horizontal,
            // .border = Rect.all(1.0),
            // .color_border = dvui.Color{ .r = 0, .g = 255, .b = 0 },
        });
        defer container.deinit();

        // random number generater for field keys
        var prng = std.Random.DefaultPrng.init(@intCast(14101998));
        const rand = prng.random();

        // left column
        {
            // vbox for title and form-fields
            var left_column = dvui.box(@src(), .{ .dir = .vertical }, .{
                .min_size_content = .{ .w = column_width },
                // .border = Rect.all(1.0),
                // .color_border = dvui.Color{ .r = 0, .g = 0, .b = 255 },
            });
            defer left_column.deinit();

            // title
            {
                const title_font = dvui.Font.FontId.fromName("Cascadia_Mono_ExtraLight");
                const font = dvui.Font{
                    .size = dvui.themeGet().font_title.size,
                    .id = title_font,
                };
                var title = dvui.textLayout(@src(), .{}, .{
                    .expand = .horizontal,
                    .background = false,
                });
                title.addText("Left", .{ .font = font });
                title.deinit();
            }

            // form-fields
            {
                const seed_a = rand.int(usize);
                const left_fields = [_]components.FormFieldOptions{
                    .{ .label = "Field 1.1", .placeholder = "Jane Doe" },
                    .{ .label = "Field 1.2", .multiline = true },
                    .{ .label = "Field 1.3" },
                };

                inline for (left_fields, 0..) |field, idx| {
                    components.form_field(seed_a + idx, field);
                }
            }
        }

        // right column
        {
            // vbox for title and form-fields
            var right_column = dvui.box(@src(), .{ .dir = .vertical }, .{
                .min_size_content = .{ .w = column_width },
                // .border = Rect.all(1.0),
                // .color_border = dvui.Color{ .r = 0, .g = 0, .b = 255 },
            });
            defer right_column.deinit();

            // title
            {
                const cmlId = dvui.Font.FontId.fromName("Cascadia_Mono_ExtraLight");
                const font = dvui.Font{
                    .size = dvui.themeGet().font_title.size,
                    .id = cmlId,
                };
                var title = dvui.textLayout(@src(), .{}, .{
                    .expand = .horizontal,
                    .background = false,
                });
                title.addText("Right", .{ .font = font });
                title.deinit();
            }

            // form-fields
            {
                const seed_b = rand.int(usize);
                const right_fields = [_]components.FormFieldOptions{
                    .{ .label = "Field 2.1", .placeholder = "Jane Doe" },
                    .{ .label = "Field 2.2", .multiline = true },
                    .{ .label = "Field 2.3" },
                };

                inline for (right_fields, 0..) |field, idx| {
                    components.form_field(seed_b + idx, field);
                }
            }
        }
    }

    return .ok;
}
