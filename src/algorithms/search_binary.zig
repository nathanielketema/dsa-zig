const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const order = std.math.order;
const sort = std.mem.sort;
const asc = std.sort.asc;

const Error = error{TypeNotSupported};

/// xs must be sorted!
pub fn binary_search_iterative(comptime T: type, xs: []const T, target: T) !?usize {
    switch (@typeInfo(T)) {
        .comptime_float, .comptime_int, .float, .int => {},
        else => return Error.TypeNotSupported,
    }
    if (xs.len == 0) return null;

    var lhs: usize = 0;
    var rhs: usize = xs.len - 1;
    while (lhs < rhs) {
        const mid = lhs + @divFloor((rhs - lhs), 2);
        if (xs[mid] >= target) {
            rhs = mid;
        } else lhs = mid + 1;
    }
    return if (xs[lhs] == target) lhs else null;
}

pub fn binary_search_recursive(comptime T: type, xs: []const T, target: T) !?usize {
    switch (@typeInfo(T)) {
        .comptime_float, .comptime_int, .float, .int => {},
        else => return Error.TypeNotSupported,
    }
    if (xs.len == 0) return null;

    const lhs: usize = 0;
    const rhs: usize = xs.len - 1;
    return binary_search_recursive_helper(T, xs, target, lhs, rhs);
}

fn binary_search_recursive_helper(
    comptime T: type,
    xs: []const T,
    target: T,
    lhs: usize,
    rhs: usize,
) ?usize {
    if (lhs >= rhs) {
        return if (xs[lhs] == target) lhs else null;
    }

    const mid = lhs + @divFloor((rhs - lhs), 2);
    if (xs[mid] >= target) {
        return binary_search_recursive_helper(T, xs, target, lhs, mid);
    } else return binary_search_recursive_helper(T, xs, target, mid + 1, rhs);
}

test {
    const T = struct {
        pub fn check(comptime T: type, xs: []const T, x: T, want: ?usize) !void {
            const xs_duped = try testing.allocator.dupe(T, xs);
            defer testing.allocator.free(xs_duped);

            sort(T, xs_duped, {}, asc(T));

            const got_iteratively = try binary_search_iterative(T, xs_duped, x);
            const got_recursively = try binary_search_recursive(T, xs_duped, x);
            try testing.expectEqual(want, got_iteratively);
            try testing.expectEqual(want, got_recursively);
        }

        pub fn check_error(comptime T: type, xs: []const T, x: T, want: Error) !void {
            const xs_duped = try testing.allocator.dupe(T, xs);
            defer testing.allocator.free(xs_duped);

            const got_iteratively = binary_search_iterative(T, xs_duped, x);
            const got_recursively = binary_search_recursive(T, xs_duped, x);
            try testing.expectError(want, got_iteratively);
            try testing.expectError(want, got_recursively);
        }
    };

    try T.check(u8, "Hello from zig!", 'z', 14);
    try T.check(u8, "Hello from zig!", 'b', null);
    try T.check(u8, &.{ 2, 7, 2, 1, 6 }, 9, null);
    try T.check(u8, &.{5}, 0, null);
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
