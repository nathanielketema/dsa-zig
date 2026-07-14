pub const linear = struct {
    pub const iterative = @import("search_linear.zig").linear_search_iterative;
    pub const recursive = @import("search_linear.zig").linear_search_recursive;
};

pub const binary = struct {
    pub const iterative = @import("search_binary.zig").binary_search_iterative;
    pub const recursive = @import("search_binary.zig").binary_search_recursive;
};

test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
}
