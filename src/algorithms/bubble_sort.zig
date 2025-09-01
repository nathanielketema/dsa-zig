const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

pub fn bubble_sort(comptime T: type, items: []T) void {
    assert(items.len > 0);
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
}
