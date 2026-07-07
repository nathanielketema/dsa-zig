pub const bubble = @import("bubble.zig").bubble;
pub const merge = @import("merge.zig").merge;
pub const insertion = @import("insertion.zig").insertion;
pub const heap = @import("heap.zig").heap;
pub const quick = @import("quick.zig").quick;
pub const selection = @import("selection.zig").selection;

test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
}
