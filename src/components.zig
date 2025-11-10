const std = @import("std");
const dvui = @import("dvui");

const main = @import("main.zig");

pub const FormFieldOptions = struct {
    label: []const u8 = "",
    multiline: bool = false,
    placeholder: []const u8 = "",
    label_options: dvui.Options = .{
        .margin = dvui.Rect{ .h = main.medium_spacing },
    },
    text_entry_options: dvui.Options = .{
        .margin = dvui.Rect{ .h = main.medium_spacing },
    },
};

pub fn form_field(key: usize, opts: FormFieldOptions) void {
    var local_opts = opts;
    var row = dvui.box(
        @src(),
        .{ .dir = .horizontal },
        .{ .id_extra = key, .expand = .horizontal },
    );
    defer row.deinit();

    local_opts.label_options.min_size_content = .{ .w = main.large_spacing * 3.0 };
    dvui.labelNoFmt(@src(), local_opts.label, .{}, local_opts.label_options);

    var text_init_options: dvui.TextEntryWidget.InitOptions = .{ .placeholder = opts.placeholder };

    if (local_opts.multiline) {
        text_init_options.multiline = true;
        local_opts.text_entry_options.min_size_content = .{ .h = main.large_spacing * 3.0 };
    }

    local_opts.text_entry_options.expand = .horizontal;
    var te = dvui.textEntry(@src(), text_init_options, local_opts.text_entry_options);
    defer te.deinit();
}
