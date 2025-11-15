const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

pub fn insertion_sort(comptime T: type, items: []T) void {
    if (items.len <= 1) return;

    for (1..items.len) |i| {
        const key = items[i];
        var j = i;
        while (j > 0 and items[j - 1] > key) : (j -= 1) {
            items[j] = items[j - 1];
        }
        items[j] = key;
    }
}

test "test" {
    var array = [_]u8{ 5, 3, 4, 1, 2 };
    insertion_sort(u8, &array);

    try testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5 }, &array);

    var list = [_]u8{ 'p', 'o', 't', 'a', 't', 'o' };
    insertion_sort(u8, &list);

    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 'a', 'o', 'o', 'p', 't', 't' },
        &list,
    );
}

test "edge cases" {
    var empty: [0]u8 = .{};
    insertion_sort(u8, &empty);
    
    var single = [_]u8{42};
    insertion_sort(u8, &single);
    try testing.expectEqual(42, single[0]);
    
    var sorted = [_]u8{1, 2, 3, 4, 5};
    insertion_sort(u8, &sorted);
    try testing.expectEqualSlices(u8, &[_]u8{1, 2, 3, 4, 5}, &sorted);
    
    var reverse = [_]u8{5, 4, 3, 2, 1};
    insertion_sort(u8, &reverse);
    try testing.expectEqualSlices(u8, &[_]u8{1, 2, 3, 4, 5}, &reverse);
    
    var dupes = [_]u8{3, 1, 3, 2, 1};
    insertion_sort(u8, &dupes);
    try testing.expectEqualSlices(u8, &[_]u8{1, 1, 2, 3, 3}, &dupes);
}

test "fuzzing multiple seeds" {
    for (0..10) |seed| {
        var random = std.Random.DefaultPrng.init(seed);
        var input: [100]u32 = undefined;
        
        for (0..input.len) |i| {
            input[i] = random.random().uintAtMost(u32, 1_000);
        }
        
        insertion_sort(u32, &input);
        
        for (0..input.len - 1) |i| {
            try testing.expect(input[i] <= input[i + 1]);
        }
    }
}
