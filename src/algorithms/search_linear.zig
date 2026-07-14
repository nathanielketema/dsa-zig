const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

const Error = error{TypeNotSupported};

pub fn linear_search_iterative(comptime T: type, xs: []const T, target: T) !?usize {
    switch (@typeInfo(T)) {
        .comptime_float, .comptime_int, .float, .int => {},
        else => return Error.TypeNotSupported,
    }

    for (xs, 0..) |x, index| {
        if (x == target) return index;
    }
    return null;
}

pub fn linear_search_recursive(comptime T: type, xs: []const T, target: T) !?usize {
    switch (@typeInfo(T)) {
        .comptime_float, .comptime_int, .float, .int => {},
        else => return Error.TypeNotSupported,
    }
    return linear_search_recursive_helper(T, xs, target, 0);
}

fn linear_search_recursive_helper(comptime T: type, xs: []const T, target: T, index: usize) ?usize {
    if (index >= xs.len) return null;
    if (xs[index] == target) return index;

    return linear_search_recursive_helper(T, xs, target, index + 1);
}

test {
    const T = struct {
        pub fn check(comptime T: type, xs: []const T, x: T, want: ?usize) !void {
            const got_iteratively = try linear_search_iterative(T, xs, x);
            const got_recursively = try linear_search_recursive(T, xs, x);
            try testing.expectEqual(want, got_iteratively);
            try testing.expectEqual(want, got_recursively);
        }

        pub fn check_error(comptime T: type, xs: []const T, x: T, want: Error) !void {
            const got_iteratively = linear_search_iterative(T, xs, x);
            const got_recursively = linear_search_recursive(T, xs, x);
            try testing.expectError(want, got_iteratively);
            try testing.expectError(want, got_recursively);
        }
    };

    try T.check(u8, "Hello from zig!", 'z', 11);
    try T.check(u8, "Hello from zig!", 'b', null);
    try T.check(u8, &.{5}, 0, null);
    try T.check(u8, &.{ 2, 7, 2, 1, 6 }, 9, null);
    try T.check(u8, &.{}, 2, null);
    try T.check(f32, &.{ 1.23, 746, 2.1 }, 1.23, 0);

    try T.check_error(
        struct {
            name: []const u8,
            age: u8,
        },
        &.{},
        .{ .name = "bob", .age = 17 },
        Error.TypeNotSupported,
    );
}
