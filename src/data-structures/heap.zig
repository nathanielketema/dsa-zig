const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;

pub const HeapMode = enum { max, min };

pub fn Heap(comptime T: type, mode: HeapMode) type {
    return struct {
        nodes: std.ArrayList(T),
        count: usize,
        allocator: Allocator,

        const Self = @This();

        const Index = enum(u32) {
            none = 0,
            _,
        };

        const Iterator = struct {
            heap: *const Self,
            index: usize,

            pub fn next(self: *Iterator) ?T {
                if (self.index >= self.heap.count) {
                    return null;
                }
                defer self.index += 1;
                return self.heap.nodes.items[self.index];
            }
        };

        /// Caller must call deinit() to free memory
        pub fn init_capacity(allocator: Allocator, capacity: usize) Allocator.Error!Self {
            return .{
                .nodes = try std.ArrayList(T).initCapacity(allocator, capacity),
                .count = 0,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.nodes.deinit(self.allocator);
        }

        pub fn add(self: *Self, element: T) !void {
            assert(self.count == self.nodes.items.len);
            try self.nodes.append(self.allocator, element);
            self.count += 1;

            const index: Index = @enumFromInt(self.count - 1);
            self.sift_up(index);
        }

        pub fn pop(self: *Self) ?T {
            assert(self.count == self.nodes.items.len);
            if (self.count == 0) {
                return null;
            }

            const popped = self.nodes.items[0];
            self.nodes.items[0] = self.nodes.items[self.count - 1];
            _ = self.nodes.pop();
            self.count -= 1;

            const index: Index = @enumFromInt(0);
            self.sift_down(index);

            return popped;
        }

        pub fn iterator(self: *const Self) Iterator {
            assert(self.count == self.nodes.items.len);
            return .{
                .heap = self,
                .index = 0,
            };
        }

        pub fn peek(self: *const Self) ?T {
            assert(self.count == self.nodes.items.len);

            if (self.count == 0) {
                return null;
            }
            return self.nodes.items[0];
        }

        fn compare(a: T, b: T) bool {
            return switch (mode) {
                .min => a < b,
                .max => a > b,
            };
        }

        fn sift_up(self: *Self, index: Index) void {
            var idx: u32 = @intFromEnum(index);
            while (idx > 0) {
                const parent_idx = (idx - 1) / 2;
                if (!compare(self.nodes.items[idx], self.nodes.items[parent_idx])) {
                    break;
                }
                std.mem.swap(T, &self.nodes.items[idx], &self.nodes.items[parent_idx]);
                idx = parent_idx;
            }
        }

        fn sift_down(self: *Self, index: Index) void {
            var idx = @intFromEnum(index);
            while (true) {
                const left_idx = (2 * idx) + 1;
                const right_idx = (2 * idx) + 2;

                if (left_idx >= self.count) {
                    break;
                }

                var possible_idx = left_idx;
                if (right_idx < self.count and
                    compare(self.nodes.items[right_idx], self.nodes.items[possible_idx]))
                {
                    possible_idx = right_idx;
                }

                if (!compare(self.nodes.items[possible_idx], self.nodes.items[idx])) {
                    break;
                }

                std.mem.swap(T, &self.nodes.items[possible_idx], &self.nodes.items[idx]);
                idx = possible_idx;
            }
        }
    };
}

test "init" {
    var heap: Heap(u8, .min) = try .init_capacity(testing.allocator, 10);
    defer heap.deinit();

    try testing.expectEqual(0, heap.count);
    try testing.expect(heap.count == heap.nodes.items.len);
}

test "add" {
    var heap: Heap(u8, .min) = try .init_capacity(testing.allocator, 10);
    defer heap.deinit();

    try heap.add(3);
    try heap.add(5);
    try heap.add(1);
    try heap.add(9);
    try heap.add(0);
    try heap.add(7);

    try testing.expectEqual(6, heap.count);
    try testing.expect(heap.count == heap.nodes.items.len);
}

test "remove" {
    var heap: Heap(u8, .min) = try .init_capacity(testing.allocator, 10);
    defer heap.deinit();

    try testing.expectEqual(null, heap.pop());
    try heap.add(13);
    try testing.expectEqual(13, heap.pop());

    try heap.add(3);
    try heap.add(5);
    try heap.add(1);
    try heap.add(9);
    try heap.add(0);
    try heap.add(7);

    try testing.expectEqual(6, heap.count);
    try testing.expect(heap.count == heap.nodes.items.len);

    try testing.expectEqual(0, heap.pop());
    try testing.expectEqual(1, heap.pop());
    try testing.expectEqual(3, heap.pop());
    try testing.expectEqual(5, heap.pop());
    try testing.expectEqual(7, heap.pop());
    try testing.expectEqual(9, heap.pop());

    try testing.expectEqual(0, heap.count);
    try testing.expect(heap.count == heap.nodes.items.len);
}

test "peek" {
    var heap: Heap(u8, .max) = try .init_capacity(testing.allocator, 10);
    defer heap.deinit();

    try heap.add(3);
    try heap.add(5);
    try heap.add(1);
    try heap.add(9);
    try heap.add(0);
    try heap.add(7);

    try testing.expectEqual(9, heap.peek());
    _ = heap.pop();
    try testing.expectEqual(7, heap.peek());
    _ = heap.pop();
    try testing.expectEqual(5, heap.peek());
    _ = heap.pop();
    try testing.expectEqual(3, heap.peek());
    _ = heap.pop();

    try testing.expectEqual(2, heap.count);
    try testing.expect(heap.count == heap.nodes.items.len);
}

test "iterator" {
    var heap: Heap(u8, .max) = try .init_capacity(testing.allocator, 10);
    defer heap.deinit();

    try heap.add(3);
    try heap.add(5);
    try heap.add(1);
    try heap.add(9);
    try heap.add(0);
    try heap.add(7);

    var it = heap.iterator();
    var count: usize = 0;
    while (it.next()) |_| {
        count += 1;
    }

    try testing.expectEqual(count, heap.count);
    try testing.expectEqual(null, it.next());
}

test "swarm testing" {
    const allocator = testing.allocator;

    const HeapToBeTested = Heap(u8, .min);
    const Model = std.PriorityQueue(u8, void, struct {
        fn lessThan(_: void, a: u8, b: u8) std.math.Order {
            return std.math.order(a, b);
        }
    }.lessThan);
    
    var heap: HeapToBeTested = try .init_capacity(allocator, 10);
    defer heap.deinit();

    var model: Model = .init(allocator, {});
    defer model.deinit();
    
    var prng: std.Random.DefaultPrng = .init(testing.random_seed);
    const random = prng.random();
    
    try testing.expectEqual(heap.count, model.count());
    
    for (0..1000) |_| {
        const swarm_distribution = random.enumValue(std.meta.DeclEnum(HeapToBeTested));
        switch (swarm_distribution) {
            .add => {
                const value = random.int(u8);
                try heap.add(value);
                try model.add(value);
                try testing.expectEqual(heap.count, model.count());
            },
            .pop => {
                const heap_result = heap.pop();
                const model_result = model.removeOrNull();
                try testing.expectEqual(model_result, heap_result);
                try testing.expectEqual(heap.count, model.count());
            },
            .peek => {
                const heap_result = heap.peek();
                const model_result = model.peek();
                try testing.expectEqual(model_result, heap_result);
            },
            .iterator => {
                var iter = heap.iterator();
                var count: usize = 0;
                while (iter.next()) |_| {
                    count += 1;
                }
                try testing.expectEqual(heap.count, count);
                try testing.expectEqual(heap.count, model.count());
            },
            else => {},
        }
    }
}
