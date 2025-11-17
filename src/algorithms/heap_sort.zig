const std = @import("std");
const Heap = @import("heap").Heap;
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;

pub fn heap_sort(comptime T: type, items: []T) !void {
    if (items.len <= 1) return;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var heap: Heap(T, .min) = try .init_capacity(allocator, items.len);
    defer heap.deinit();

    for (items) |item| {
        try heap.add(item);
    }

    var i: usize = 0;
    while (heap.pop()) |item| : (i += 1) {
        items[i] = item;
    }
}

test "test" {
    var array = [_]u8{ 5, 3, 4, 1, 2 };
    try heap_sort(u8, &array);

    try testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5 }, &array);

    var list = [_]u8{ 'p', 'o', 't', 'a', 't', 'o' };
    try heap_sort(u8, &list);

    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 'a', 'o', 'o', 'p', 't', 't' },
        &list,
    );
}

test "edge cases" {
    var empty: [0]u8 = .{};
    try heap_sort(u8, &empty);
    
    var single = [_]u8{42};
    try heap_sort(u8, &single);
    try testing.expectEqual(42, single[0]);
    
    var sorted = [_]u8{1, 2, 3, 4, 5};
    try heap_sort(u8, &sorted);
    try testing.expectEqualSlices(u8, &[_]u8{1, 2, 3, 4, 5}, &sorted);
    
    var reverse = [_]u8{5, 4, 3, 2, 1};
    try heap_sort(u8, &reverse);
    try testing.expectEqualSlices(u8, &[_]u8{1, 2, 3, 4, 5}, &reverse);
    
    var dupes = [_]u8{3, 1, 3, 2, 1};
    try heap_sort(u8, &dupes);
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
        
        try heap_sort(u32, &input);
        
        for (0..input.len - 1) |i| {
            try testing.expect(input[i] <= input[i + 1]);
        }
    }
}
