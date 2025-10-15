const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const bubble_sort = @import("bubble_sort.zig").bubble_sort;
const Allocator = std.mem.Allocator;

pub fn merge_sort(allocator: Allocator, comptime T: type, list: []T) !void {
    if (list.len <= 1) return;

    // allocate memory once
    const scratch = try allocator.alloc(T, list.len);
    defer allocator.free(scratch);

    merge_sort_helper(T, list, scratch);
}

fn merge_sort_helper(comptime T: type, list: []T, scratch: []T) void {
    assert(list.len <= scratch.len);
    if (list.len <= 1) return;

    // Use bubble sort for small arrays for efficiency
    if (list.len <= 16) {
        bubble_sort(T, list);
        return;
    }

    const mid = list.len / 2;
    const left = list[0..mid];
    const right = list[mid..list.len];

    merge_sort_helper(T, left, scratch[0..mid]);
    merge_sort_helper(T, right, scratch[mid..list.len]);

    merge(T, left, right, list, scratch);
}

fn merge(
    comptime T: type,
    left: []const T,
    right: []const T,
    result: []T,
    scratch: []T,
) void {
    assert(result.len == left.len + right.len);

    // Copy to scratch buffer for the merge
    @memcpy(scratch[0..left.len], left);
    @memcpy(scratch[left.len..result.len], right);

    var left_index: usize = 0;
    var right_index: usize = left.len;
    var result_index: usize = 0;

    while (left_index < left.len and right_index < result.len) {
        if (scratch[left_index] <= scratch[right_index]) {
            result[result_index] = scratch[left_index];
            left_index += 1;
        } else {
            result[result_index] = scratch[right_index];
            right_index += 1;
        }
        result_index += 1;
    }

    while (left_index < left.len) {
        result[result_index] = scratch[left_index];
        left_index += 1;
        result_index += 1;
    }

    while (right_index < result.len) {
        result[result_index] = scratch[right_index];
        right_index += 1;
        result_index += 1;
    }
}

test "merge_sort u8" {
    var list = [_]u8{ 1, 7, 2, 6 };
    try merge_sort(testing.allocator, u8, &list);
    try testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 6, 7 }, &list);
}

test "merge_sort i32" {
    var list = [_]i32{ 5, 2, 8, 1, 9, 3, 7, 4, 6 };
    try merge_sort(testing.allocator, i32, &list);
    try testing.expectEqualSlices(
        i32,
        &[_]i32{ 1, 2, 3, 4, 5, 6, 7, 8, 9 },
        &list,
    );
}

test "merge_sort empty and single" {
    var empty = [_]i32{};
    try merge_sort(testing.allocator, i32, &empty);
    try testing.expectEqual(@as(usize, 0), empty.len);

    var single = [_]i32{42};
    try merge_sort(testing.allocator, i32, &single);
    try testing.expectEqual(@as(i32, 42), single[0]);
}

test "merge_sort duplicates" {
    var list = [_]i32{ 3, 1, 4, 1, 5, 9, 2, 6, 5, 3 };
    try merge_sort(testing.allocator, i32, &list);
    try testing.expectEqualSlices(
        i32,
        &[_]i32{ 1, 1, 2, 3, 3, 4, 5, 5, 6, 9 },
        &list,
    );
}

test "merge_sort floats" {
    var list = [_]f32{ 3.14, 1.41, 2.71, 0.57 };
    try merge_sort(testing.allocator, f32, &list);
    try testing.expectEqualSlices(
        f32,
        &[_]f32{ 0.57, 1.41, 2.71, 3.14 },
        &list,
    );
}
