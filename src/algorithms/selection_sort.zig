const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

pub fn selection_sort(comptime T: type, items: []T) void {
    if (items.len <= 1) return;

    for (0..items.len - 1) |i| {
        var min_index = i;
        for (i + 1..items.len) |j| {
            if (items[j] < items[min_index]) {
                min_index = j;
            }
        }

        if (min_index != i) {
            std.mem.swap(T, &items[i], &items[min_index]);
        }
    }
}

test "test" {
    var array = [_]u8{ 5, 3, 4, 1, 2 };
    selection_sort(u8, &array);

    try testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5 }, &array);

    var list = [_]u8{ 'p', 'o', 't', 'a', 't', 'o' };
    selection_sort(u8, &list);

    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 'a', 'o', 'o', 'p', 't', 't' },
        &list,
    );
}

test "edge cases" {
    var empty: [0]u8 = .{};
    selection_sort(u8, &empty);

    var single = [_]u8{42};
    selection_sort(u8, &single);
    try testing.expectEqual(42, single[0]);

    var sorted = [_]u8{1, 2, 3, 4, 5};
    selection_sort(u8, &sorted);
    try testing.expectEqualSlices(u8, &[_]u8{1, 2, 3, 4, 5}, &sorted);

    var reverse = [_]u8{5, 4, 3, 2, 1};
    selection_sort(u8, &reverse);
    try testing.expectEqualSlices(u8, &[_]u8{1, 2, 3, 4, 5}, &reverse);

    var dupes = [_]u8{3, 1, 3, 2, 1};
    selection_sort(u8, &dupes);
    try testing.expectEqualSlices(u8, &[_]u8{1, 1, 2, 3, 3}, &dupes);
}

test "fuzzing multiple seeds" {
    for (0..10) |seed| {
        var prng: std.Random.DefaultPrng = .init(seed);
        const random = prng.random();
        var input: [100]u32 = undefined;

        for (0..input.len) |i| {
            input[i] = random.uintAtMost(u32, 1_000);
        }

        selection_sort(u32, &input);

        for (0..input.len - 1) |i| {
            try testing.expect(input[i] <= input[i + 1]);
        }
    }
}
