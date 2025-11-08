const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;

pub fn Array_List(comptime T: type) type {
    return struct {
        items: []T,
        count: usize,
        capacity: usize,

        const ArrayList = @This();
        const default_capacity = 10;

        /// Caller must free memory by calling deinit()
        pub fn init(allocator: Allocator) Allocator.Error!ArrayList {
            return init_capacity(allocator, default_capacity);
        }

        /// Caller must free memory by calling deinit()
        pub fn init_capacity(allocator: Allocator, capacity: usize) Allocator.Error!ArrayList {
            assert(capacity > 0);
            const buffer = try allocator.alloc(T, capacity);
            return .{
                .items = buffer,
                .count = 0,
                .capacity = capacity,
            };
        }

        pub fn deinit(self: *ArrayList, allocator: Allocator) void {
            assert(self.count <= self.capacity);

            allocator.free(self.items);
            self.* = undefined;
        }

        pub fn push(self: *ArrayList, allocator: Allocator, item: T) Allocator.Error!void {
            assert(self.count <= self.capacity);

            if (self.count == self.capacity) {
                const new_capacity = self.capacity * 2;
                try self.new(allocator, new_capacity);
            }

            self.items[self.count] = item;
            self.count += 1;
        }

        pub fn pop(self: *ArrayList) ?T {
            assert(self.count <= self.capacity);

            if (self.count == 0) return null;

            const popped = self.items[self.count - 1];
            self.count -= 1;
            return popped;
        }

        pub fn add_at(
            self: *ArrayList,
            allocator: Allocator,
            index: usize,
            item: T,
        ) (Allocator.Error || error{IndexOutOfBounds})!void {
            assert(self.count <= self.capacity);

            if (index > self.count) {
                return error.IndexOutOfBounds;
            }

            if (self.count == self.capacity) {
                const new_capacity = self.capacity * 2;
                try self.new(allocator, new_capacity);
            }

            if (index < self.count) {
                var i = self.count;
                while (i > index) : (i -= 1) {
                    self.items[i] = self.items[i - 1];
                }
            }
            self.items[index] = item;
            self.count += 1;
        }

        pub fn remove(self: *ArrayList, item: T) bool {
            assert(self.count <= self.capacity);

            const index: usize = for (self.items[0..self.count], 0..) |itm, i| {
                if (std.meta.eql(itm, item)) break i;
            } else return false;

            for (index..self.count - 1) |i| {
                self.items[i] = self.items[i + 1];
            }

            self.count -= 1;
            return true;
        }

        pub fn clear(self: *ArrayList) void {
            assert(self.count <= self.capacity);
            self.count = 0;
        }

        pub fn contains(self: *const ArrayList, item: T) bool {
            assert(self.count <= self.capacity);

            for (self.items[0..self.count]) |itm| {
                if (std.meta.eql(itm, item)) {
                    return true;
                }
            }
            return false;
        }

        /// Caller must free memory by calling deinit()
        pub fn clone(self: *const ArrayList, allocator: Allocator) Allocator.Error!ArrayList {
            assert(self.count <= self.capacity);

            var cloned = try init_capacity(allocator, self.capacity);
            @memcpy(cloned.items[0..self.count], self.items[0..self.count]);
            cloned.count = self.count;

            return cloned;
        }

        pub fn from_slice(allocator: Allocator, slice: []const T) Allocator.Error!ArrayList {
            var list = try init_capacity(allocator, slice.len);
            @memcpy(list.items[0..slice.len], slice);
            list.count = slice.len;
            return list;
        }

        fn new(self: *ArrayList, allocator: Allocator, new_capacity: usize) Allocator.Error!void {
            assert(new_capacity > 0);
            assert(self.count < new_capacity);

            const new_memory = try allocator.realloc(self.items, new_capacity);
            assert(new_memory.len == new_capacity);

            self.items = new_memory;
            self.capacity = new_capacity;
            assert(self.capacity >= self.count);
        }
    };
}

test "init/deinit" {
    var array_list: Array_List(u8) = try .init_capacity(testing.allocator, 1);
    defer array_list.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 0), array_list.count);
}

test "push" {
    const allocator = testing.allocator;
    var array_list: Array_List(u8) = try .init_capacity(allocator, 2);
    defer array_list.deinit(allocator);

    try array_list.push(allocator, 2);
    try array_list.push(allocator, 4);
    try array_list.push(allocator, 6);
    try array_list.push(allocator, 8);
    try array_list.push(allocator, 9);

    try testing.expectEqual(@as(usize, 5), array_list.count);
}

test "pop" {
    const allocator = testing.allocator;
    var array_list: Array_List(u8) = try .init_capacity(allocator, 2);
    defer array_list.deinit(allocator);

    try testing.expectEqual(null, array_list.pop());
    try array_list.push(allocator, 2);
    try array_list.push(allocator, 4);
    try array_list.push(allocator, 6);
    try array_list.push(allocator, 8);
    try array_list.push(allocator, 9);

    try testing.expectEqual(9, array_list.pop());
    try testing.expectEqual(8, array_list.pop());
    try testing.expectEqual(6, array_list.pop());

    try testing.expectEqual(@as(usize, 2), array_list.count);
}

test "add at" {
    const allocator = testing.allocator;
    var array_list: Array_List(u8) = try .init(allocator);
    defer array_list.deinit(allocator);

    try array_list.add_at(allocator, 0, 4);
    try array_list.add_at(allocator, 1, 1);
    try array_list.add_at(allocator, 2, 2);
    try array_list.add_at(allocator, 3, 9);
    try array_list.add_at(allocator, 4, 0);
    try array_list.add_at(allocator, 5, 3);

    try testing.expectEqual(@as(usize, 6), array_list.count);
}

test "remove" {
    const allocator = testing.allocator;
    var array_list: Array_List(u8) = try .init_capacity(allocator, 2);
    defer array_list.deinit(allocator);

    try testing.expect(!array_list.remove(6));
    try array_list.push(allocator, 2);
    try array_list.push(allocator, 4);
    try array_list.push(allocator, 6);
    try array_list.push(allocator, 8);
    try array_list.push(allocator, 9);

    try testing.expect(array_list.remove(2));
    try testing.expect(!array_list.remove(2));
    try testing.expect(array_list.remove(8));
    try testing.expect(array_list.remove(9));
    try testing.expect(array_list.remove(4));

    try testing.expectEqual(@as(usize, 1), array_list.count);
}

test "clear" {
    const allocator = testing.allocator;
    var array_list: Array_List(u8) = try .init_capacity(allocator, 10);
    defer array_list.deinit(allocator);

    try array_list.push(allocator, 2);
    try array_list.push(allocator, 4);
    try array_list.push(allocator, 6);
    try array_list.push(allocator, 8);
    try array_list.push(allocator, 9);
    try testing.expectEqual(@as(usize, 5), array_list.count);
    try testing.expectEqual(@as(usize, 10), array_list.capacity);
    try testing.expect(array_list.contains(6));

    array_list.clear();

    try testing.expect(!array_list.contains(6));
    try testing.expectEqual(@as(usize, 0), array_list.count);
    try testing.expectEqual(@as(usize, 10), array_list.capacity);
}

test "contains" {
    const allocator = testing.allocator;
    var array_list: Array_List(u8) = try .init_capacity(allocator, 2);
    defer array_list.deinit(allocator);

    try array_list.push(allocator, 2);
    try array_list.push(allocator, 4);
    try array_list.push(allocator, 6);
    try array_list.push(allocator, 8);
    try array_list.push(allocator, 9);

    try testing.expect(array_list.contains(6));
    try testing.expect(!array_list.contains(0));
    try testing.expect(array_list.contains(8));

    try testing.expectEqual(@as(usize, 5), array_list.count);
}

test "clone" {
    const allocator = testing.allocator;
    var array_list: Array_List(u8) = try .init_capacity(allocator, 10);
    defer array_list.deinit(allocator);

    try array_list.push(allocator, 2);
    try array_list.push(allocator, 4);
    try array_list.push(allocator, 6);
    try array_list.push(allocator, 8);
    try array_list.push(allocator, 9);
    try testing.expectEqual(@as(usize, 5), array_list.count);
    try testing.expect(array_list.contains(4));
    try testing.expect(array_list.contains(9));

    var cloned: Array_List(u8) = try array_list.clone(allocator);
    defer cloned.deinit(allocator);

    try testing.expectEqual(@as(usize, 5), cloned.count);
    try testing.expect(cloned.contains(4));
    try testing.expect(cloned.contains(9));
}

test "from slice" {
    const allocator = testing.allocator;
    var slice = [_]u8{ 1, 3, 4, 5, 7 };

    var array_list: Array_List(u8) = try .from_slice(allocator, &slice);
    defer array_list.deinit(allocator);
}

test "complete API" {
    const allocator = testing.allocator;
    var array_list: Array_List(u8) = try .init(allocator);
    defer array_list.deinit(allocator);

    try testing.expectEqual(@as(usize, 0), array_list.count);

    try array_list.push(allocator, 2);
    try array_list.push(allocator, 4);
    try array_list.push(allocator, 6);
    try array_list.push(allocator, 8);

    try array_list.add_at(allocator, 1, 3);
    try array_list.add_at(allocator, 3, 5);
    try array_list.add_at(allocator, 4, 7);
    try testing.expect(array_list.count == 7);

    try testing.expect(array_list.contains(2));
    try testing.expect(array_list.contains(3));
    try testing.expect(array_list.contains(4));
    try testing.expect(array_list.contains(5));

    try testing.expectEqual(8, array_list.pop());
    try testing.expectEqual(6, array_list.pop());
    try testing.expect(array_list.count == 5);

    var new_clone = try array_list.clone(allocator);
    defer new_clone.deinit(allocator);

    try testing.expect(new_clone.contains(2));
    try testing.expect(new_clone.contains(3));
    try testing.expect(!new_clone.contains(8));

    try testing.expect(array_list.remove(2));
    try testing.expect(array_list.remove(3));
    try testing.expect(array_list.count == 3);

    array_list.clear();
    try testing.expect(array_list.count == 0);
}

test "swarm test" {
    const allocator = testing.allocator;
    var prng: std.Random.DefaultPrng = .init(testing.random_seed);
    const random: std.Random = prng.random();

    const ArrayList = Array_List(u8);
    const Model = std.ArrayList(u8);

    var array_list: ArrayList = try .init_capacity(allocator, 100);
    defer array_list.deinit(allocator);

    var model: Model = try .initCapacity(allocator, 100);
    defer model.deinit(allocator);

    for (0..1000) |_| {
        const swarm_testing = random.enumValue(std.meta.DeclEnum(ArrayList));
        switch (swarm_testing) {
            .push => {
                try array_list.push(allocator, 1);
                try array_list.push(allocator, 2);
                try model.append(allocator, 1);
                try model.append(allocator, 2);
                assert(model.items.len == array_list.count);
            },
            .pop => {
                try array_list.push(allocator, 1);
                try array_list.push(allocator, 2);
                try model.append(allocator, 1);
                try model.append(allocator, 2);

                assert(array_list.pop() == model.pop());
                assert(array_list.pop() == model.pop());
                assert(array_list.pop() == model.pop());
                assert(model.items.len == array_list.count);
            },
            else => {},
        }
    }
}
