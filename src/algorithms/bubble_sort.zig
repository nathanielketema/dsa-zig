const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

pub fn bubble_sort(comptime T: type, items: []T) void {
    if (items.len <= 0) return;
    var swapped: bool = undefined;
    for (0..items.len - 1) |i| {
        swapped = false;
        for (0..items.len - i - 1) |j| {
            if (items[j] > items[j + 1]) {
                std.mem.swap(T, &items[j], &items[j + 1]);
                swapped = true;
            }
        }

        if (!swapped) {
            break;
        }
    }
}

test "test" {
    var array = [_]u8{ 5, 3, 4, 1, 2 };
    bubble_sort(u8, &array);

    try testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5 }, &array);

    var list = [_]u8{ 'n', 'a', 't', 'h', 'a', 'n', 'i', 'e', 'l' };
    bubble_sort(u8, &list);

    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 'a', 'a', 'e', 'h', 'i', 'l', 'n', 'n', 't' },
        &list,
    );
}

test "fuzzing" {
    var random = std.Random.DefaultPrng.init(23);
    var input: [1_000]u32 = undefined;
    _ = &input;
    for (0..input.len) |i| {
        input[i] = random.random().uintAtMost(u32, 1_000);
    }

    bubble_sort(u32, &input);
    for (0..input.len - 1) |i| {
        try testing.expect(input[i] <= input[i + 1]);
    }
}
