const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;

pub fn ArrayList(comptime T: type) type {
    return struct {
        items: []T,
        count: usize,
        capacity: usize,

        const Self = @This();

        pub const empty: Self = .{
            .items = &.{},
            .count = 0,
            .capacity = 0,
        };

        /// Caller must call deinit() to free memory
        pub fn init_capacity(allocator: Allocator, capacity: usize) Allocator.Error!Self {
            assert(capacity > 0);

            const buffer = try allocator.alloc(T, capacity);

            return Self{
                .items = buffer,
                .count = 0,
                .capacity = capacity,
            };
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            assert(self.count <= self.capacity);

            if (self.capacity > 0) {
                allocator.free(self.items[0..self.capacity]);
            }
            self.* = undefined;
        }

        fn ensure_total_capacity(
            self: *Self,
            allocator: Allocator,
            new_capacity: usize,
        ) Allocator.Error!void {
            assert(self.count <= self.capacity);
            assert(new_capacity > 0);

            if (self.capacity >= new_capacity) return;

            const old_memory = self.items[0..self.capacity];
            const new_memory = try allocator.realloc(old_memory, new_capacity);
            assert(new_memory.len == new_capacity);

            self.items = new_memory;
            self.capacity = new_capacity;
            assert(self.capacity >= self.count);
        }

        pub fn push(self: *Self, allocator: Allocator, item: T) Allocator.Error!void {
            assert(self.count <= self.capacity);

            const new_count = self.count + 1;
            if (new_count > self.capacity) {
                const new_capacity = self.capacity + self.capacity / 2 + 8;
                try self.ensure_total_capacity(allocator, new_capacity);
            }
            assert(self.count < self.capacity);

            self.items[self.count] = item;
            self.count = new_count;
        }

        /// Insert an item at the specified index.
        /// All items at index are shifted right.
        pub fn add_at(
            self: *Self,
            allocator: Allocator,
            index: usize,
            item: T,
        ) Allocator.Error!void {
            assert(self.count <= self.capacity);
            assert(index <= self.count);

            const new_count = self.count + 1;
            if (new_count > self.capacity) {
                const new_capacity = self.capacity + self.capacity / 2 + 8;
                try self.ensure_total_capacity(allocator, new_capacity);
            }
            assert(self.count < self.capacity);

            var i = self.count;
            while (i > index) : (i -= 1) {
                self.items[i] = self.items[i - 1];
            }

            self.items[index] = item;
            self.count = new_count;
            assert(self.count <= self.capacity);
        }

        pub fn pop(self: *Self) ?T {
            assert(self.count <= self.capacity);

            if (self.count == 0) return null;

            const item = self.items[self.count - 1];
            self.count -= 1;

            assert(self.count < self.capacity);
            return item;
        }

        pub fn remove(self: *Self, item: T) bool {
            assert(self.count <= self.capacity);

            const index_found = for (self.items[0..self.count], 0..) |list_item, i| {
                if (std.meta.eql(list_item, item)) break i;
            } else return false;
            assert(index_found < self.count);

            var i = index_found;
            while (i < self.count - 1) : (i += 1) {
                self.items[i] = self.items[i + 1];
            }

            self.count -= 1;
            assert(self.count < self.capacity);
            return true;
        }

        /// Caller must call deinit.
        pub fn clone(self: *const Self, allocator: Allocator) Allocator.Error!Self {
            assert(self.count <= self.capacity);

            if (self.count == 0) return empty;

            const buffer = try allocator.alloc(T, self.capacity);
            assert(buffer.len == self.capacity);

            @memcpy(buffer[0..self.count], self.items[0..self.count]);

            const result = Self{
                .items = buffer,
                .count = self.count,
                .capacity = self.capacity,
            };
            assert(result.count == self.count);
            assert(result.capacity == self.capacity);

            return result;
        }
    };
}

test "ArrayList: init_capacity and deinit" {
    var list = try ArrayList(u32).init_capacity(testing.allocator, 10);
    defer list.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 0), list.count);
    try testing.expectEqual(@as(usize, 10), list.capacity);
}

test "ArrayList: push" {
    var list = try ArrayList(u32).init_capacity(testing.allocator, 4);
    defer list.deinit(testing.allocator);

    try list.push(testing.allocator, 10);
    try testing.expectEqual(@as(usize, 1), list.count);
    try testing.expectEqual(@as(u32, 10), list.items[0]);

    try list.push(testing.allocator, 20);
    try testing.expectEqual(@as(usize, 2), list.count);
    try testing.expectEqual(@as(u32, 20), list.items[1]);
}

test "ArrayList: push grows capacity" {
    var list = try ArrayList(u32).init_capacity(testing.allocator, 2);
    defer list.deinit(testing.allocator);

    try list.push(testing.allocator, 1);
    try list.push(testing.allocator, 2);
    try testing.expectEqual(@as(usize, 2), list.count);
    try testing.expectEqual(@as(usize, 2), list.capacity);

    try list.push(testing.allocator, 3);
    try testing.expectEqual(@as(usize, 3), list.count);
    try testing.expect(list.capacity > 2);
}

test "ArrayList: add_at inserts at beginning" {
    var list = try ArrayList(u32).init_capacity(testing.allocator, 10);
    defer list.deinit(testing.allocator);

    try list.push(testing.allocator, 10);
    try list.push(testing.allocator, 20);
    try list.add_at(testing.allocator, 0, 5);

    try testing.expectEqual(@as(usize, 3), list.count);
    try testing.expectEqual(@as(u32, 5), list.items[0]);
    try testing.expectEqual(@as(u32, 10), list.items[1]);
    try testing.expectEqual(@as(u32, 20), list.items[2]);
}

test "ArrayList: add_at inserts in middle" {
    var list = try ArrayList(u32).init_capacity(testing.allocator, 10);
    defer list.deinit(testing.allocator);

    try list.push(testing.allocator, 10);
    try list.push(testing.allocator, 30);
    try list.add_at(testing.allocator, 1, 20);

    try testing.expectEqual(@as(usize, 3), list.count);
    try testing.expectEqual(@as(u32, 10), list.items[0]);
    try testing.expectEqual(@as(u32, 20), list.items[1]);
    try testing.expectEqual(@as(u32, 30), list.items[2]);
}

test "ArrayList: add_at appends at end" {
    var list = try ArrayList(u32).init_capacity(testing.allocator, 10);
    defer list.deinit(testing.allocator);

    try list.push(testing.allocator, 10);
    try list.add_at(testing.allocator, 1, 20);

    try testing.expectEqual(@as(usize, 2), list.count);
    try testing.expectEqual(@as(u32, 10), list.items[0]);
    try testing.expectEqual(@as(u32, 20), list.items[1]);
}

test "ArrayList: pop on non-empty list" {
    var list = try ArrayList(u32).init_capacity(testing.allocator, 10);
    defer list.deinit(testing.allocator);

    try list.push(testing.allocator, 10);
    try list.push(testing.allocator, 20);
    try list.push(testing.allocator, 30);

    const removed = list.pop();
    try testing.expectEqual(@as(u32, 30), removed.?);
    try testing.expectEqual(@as(usize, 2), list.count);
}

test "ArrayList: pop on empty list" {
    var list = try ArrayList(u32).init_capacity(testing.allocator, 10);
    defer list.deinit(testing.allocator);

    const removed = list.pop();
    try testing.expect(removed == null);
}

test "ArrayList: remove finds and removes item" {
    var list = try ArrayList(u32).init_capacity(testing.allocator, 10);
    defer list.deinit(testing.allocator);

    try list.push(testing.allocator, 10);
    try list.push(testing.allocator, 20);
    try list.push(testing.allocator, 30);

    const found = list.remove(20);
    try testing.expect(found);
    try testing.expectEqual(@as(usize, 2), list.count);
    try testing.expectEqual(@as(u32, 10), list.items[0]);
    try testing.expectEqual(@as(u32, 30), list.items[1]);
}

test "ArrayList: remove returns false when item not found" {
    var list = try ArrayList(u32).init_capacity(testing.allocator, 10);
    defer list.deinit(testing.allocator);

    try list.push(testing.allocator, 10);
    try list.push(testing.allocator, 20);

    const found = list.remove(99);
    try testing.expect(!found);
    try testing.expectEqual(@as(usize, 2), list.count);
}

test "ArrayList: remove only removes first occurrence" {
    var list = try ArrayList(u32).init_capacity(testing.allocator, 10);
    defer list.deinit(testing.allocator);

    try list.push(testing.allocator, 10);
    try list.push(testing.allocator, 20);
    try list.push(testing.allocator, 10);

    const found = list.remove(10);
    try testing.expect(found);
    try testing.expectEqual(@as(usize, 2), list.count);
    try testing.expectEqual(@as(u32, 20), list.items[0]);
    try testing.expectEqual(@as(u32, 10), list.items[1]);
}

test "ArrayList: clone creates independent copy" {
    var list = try ArrayList(u32).init_capacity(testing.allocator, 10);
    defer list.deinit(testing.allocator);

    try list.push(testing.allocator, 10);
    try list.push(testing.allocator, 20);

    var cloned = try list.clone(testing.allocator);
    defer cloned.deinit(testing.allocator);

    try testing.expectEqual(list.count, cloned.count);
    try testing.expectEqual(list.capacity, cloned.capacity);
    try testing.expectEqual(@as(u32, 10), cloned.items[0]);
    try testing.expectEqual(@as(u32, 20), cloned.items[1]);

    // Verify independence by modifying original.
    try list.push(testing.allocator, 30);
    try testing.expectEqual(@as(usize, 3), list.count);
    try testing.expectEqual(@as(usize, 2), cloned.count);
}

test "ArrayList: empty constant" {
    const EmptyList = ArrayList(u32);

    try testing.expectEqual(@as(usize, 0), EmptyList.empty.count);
    try testing.expectEqual(@as(usize, 0), EmptyList.empty.capacity);
}

test "ArrayList: swarm test against std.ArrayList" {
    var prng = std.Random.DefaultPrng.init(std.testing.random_seed);
    const random = prng.random();

    const Model = std.ArrayList(u32);
    const Array = ArrayList(u32);

    var model: Model = .{};
    defer model.deinit(testing.allocator);

    var array = try Array.init_capacity(testing.allocator, 8);
    defer array.deinit(testing.allocator);

    for (0..1000) |_| {
        assert(array.count == model.items.len);

        for (model.items, 0..) |item, i| {
            assert(array.items[i] == item);
        }

        const swarm_distribution = random.enumValue(std.meta.DeclEnum(Array));

        switch (swarm_distribution) {
            .push => {
                const value = random.int(u32);
                try array.push(testing.allocator, value);
                try model.append(testing.allocator, value);
                assert(array.count == model.items.len);
                assert(array.items[array.count - 1] == value);
            },
            .pop => {
                const array_result = array.pop();
                const model_result = if (model.items.len > 0) model.pop() else null;
                assert(std.meta.eql(array_result, model_result));
                assert(array.count == model.items.len);
            },
            .add_at => {
                if (array.count > 0 or random.boolean()) {
                    const index = random.uintLessThanBiased(usize, array.count + 1);
                    const value = random.int(u32);
                    try array.add_at(testing.allocator, index, value);
                    try model.insert(testing.allocator, index, value);
                    assert(array.count == model.items.len);
                    assert(array.items[index] == value);
                }
            },
            .remove => {
                if (array.count > 0) {
                    const index = random.uintLessThanBiased(usize, array.count);
                    const value = array.items[index];

                    const array_found = array.remove(value);

                    const model_found = for (model.items, 0..) |item, i| {
                        if (item == value) {
                            _ = model.orderedRemove(i);
                            break true;
                        }
                    } else false;

                    assert(array_found == model_found);
                    assert(array.count == model.items.len);
                }
            },
            .clone => {
                var array_clone = try array.clone(testing.allocator);
                defer array_clone.deinit(testing.allocator);

                var model_clone = try model.clone(testing.allocator);
                defer model_clone.deinit(testing.allocator);

                assert(array_clone.count == model_clone.items.len);
                assert(array_clone.count == array.count);
                for (model_clone.items, 0..) |item, i| {
                    assert(array_clone.items[i] == item);
                }
            },
            else => {},
        }
    }

    assert(array.count == model.items.len);
    for (model.items, 0..) |item, i| {
        assert(array.items[i] == item);
    }
}
