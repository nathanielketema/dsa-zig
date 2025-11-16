const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

pub fn quick_sort(comptime T: type, items: []T) void {
    if (items.len <= 1) return;
    quick_sort_helper(T, items, 0, items.len - 1);
}

fn quick_sort_helper(comptime T: type, items: []T, low: usize, high: usize) void {
    if (low >= high) {
        return;
    }
    const pivot_index = partition(T, items, low, high);
    
    if (pivot_index > low) {
        quick_sort_helper(T, items, low, pivot_index - 1);
    }
    
    if (pivot_index < high) {
        quick_sort_helper(T, items, pivot_index + 1, high);
    }
}

fn partition(comptime T: type, items: []T, low: usize, high: usize) usize {
    const pivot = items[high];
    var i = low;
    
    for (low..high) |j| {
        if (items[j] <= pivot) {
            std.mem.swap(T, &items[i], &items[j]);
            i += 1;
        }
    }
    std.mem.swap(T, &items[i], &items[high]);
    return i;
}

test "test" {
    var array = [_]u8{ 5, 3, 4, 1, 2 };
    quick_sort(u8, &array);

    try testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5 }, &array);

    var list = [_]u8{ 'p', 'o', 't', 'a', 't', 'o' };
    quick_sort(u8, &list);

    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 'a', 'o', 'o', 'p', 't', 't' },
        &list,
    );
}

test "edge cases" {
    var empty: [0]u8 = .{};
    quick_sort(u8, &empty);

    var single = [_]u8{42};
    quick_sort(u8, &single);
    try testing.expectEqual(42, single[0]);

    var sorted = [_]u8{ 1, 2, 3, 4, 5 };
    quick_sort(u8, &sorted);
    try testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5 }, &sorted);

    var reverse = [_]u8{ 5, 4, 3, 2, 1 };
    quick_sort(u8, &reverse);
    try testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5 }, &reverse);

    var dupes = [_]u8{ 3, 1, 3, 2, 1 };
    quick_sort(u8, &dupes);
    try testing.expectEqualSlices(u8, &[_]u8{ 1, 1, 2, 3, 3 }, &dupes);
}

test "fuzzing multiple seeds" {
    for (0..10) |seed| {
        var prng: std.Random.DefaultPrng = .init(seed);
        const random = prng.random();
        var input: [100]u32 = undefined;

        for (0..input.len) |i| {
            input[i] = random.uintAtMost(u32, 1_000);
        }

        quick_sort(u32, &input);

        for (0..input.len - 1) |i| {
            try testing.expect(input[i] <= input[i + 1]);
        }
    }
}
