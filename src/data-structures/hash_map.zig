const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;

pub fn Hash_Map(comptime K: type, comptime V: type) type {
    return struct {
        keys: []?K,
        values: []V,
        count: usize,
        capacity: usize,
        allocator: Allocator,

        const HashMap = @This();
        const load_factor_percent = 80;
        const default_capacity = 100;

        pub const Entry = struct {
            key: K,
            value: V,
        };

        pub const Iterator = struct {
            hash_map: *const HashMap,
            index: usize,

            pub fn next(self: *Iterator) ?Entry {
                while (self.index < self.hash_map.capacity) {
                    defer self.index += 1;
                    if (self.hash_map.keys[self.index]) |key| {
                        return Entry{
                            .key = key,
                            .value = self.hash_map.values[self.index],
                        };
                    }
                }

                return null;
            }
        };

        /// Caller must free memory using deinit()
        pub fn init(allocator: Allocator) Allocator.Error!HashMap {
            return init_capacity(allocator, default_capacity);
        }

        /// Caller must free memory using deinit()
        pub fn init_capacity(allocator: Allocator, capacity: usize) Allocator.Error!HashMap {
            assert(capacity > 0);

            const key = try allocator.alloc(?K, capacity);
            @memset(key, null);
            const value = try allocator.alloc(V, capacity);

            return .{
                .keys = key,
                .values = value,
                .count = 0,
                .capacity = capacity,
                .allocator = allocator,
            };
        }

        pub fn deinit(hash_map: *HashMap) void {
            assert(hash_map.count <= hash_map.capacity);

            hash_map.allocator.free(hash_map.keys);
            hash_map.allocator.free(hash_map.values);
            hash_map.* = undefined;
        }

        pub fn put(hash_map: *HashMap, key: K, value: V) Allocator.Error!void {
            assert(hash_map.count <= hash_map.capacity);

            const it_should_grow = (hash_map.count * 100) >= (hash_map.capacity * load_factor_percent);
            if (it_should_grow) {
                const new_capacity = hash_map.capacity * 2;
                try hash_map.new(new_capacity);
            }

            var index = hash_key(key, hash_map.capacity);
            var probes: usize = 0;
            while (probes < hash_map.capacity) : (probes += 1) {
                const found_key = hash_map.keys[index] orelse {
                    hash_map.keys[index] = key;
                    hash_map.values[index] = value;
                    hash_map.count += 1;
                    return;
                };

                if (std.meta.eql(found_key, key)) {
                    hash_map.values[index] = value;
                    return;
                }
                index = (index + 1) % hash_map.capacity;
            }
        }

        pub fn remove(hash_map: *HashMap, key: K) Allocator.Error!bool {
            assert(hash_map.count < hash_map.capacity);

            var index = hash_key(key, hash_map.capacity);
            var probes: usize = 0;
            while (probes < hash_map.capacity) : (probes += 1) {
                const found_key = hash_map.keys[index] orelse return false;
                if (std.meta.eql(found_key, key)) {
                    hash_map.keys[index] = null;
                    hash_map.values[index] = undefined;
                    hash_map.count -= 1;

                    // Re hash to avoid gaps
                    try hash_map.new(hash_map.capacity);
                    return true;
                }
                index = (index + 1) % hash_map.capacity;
            }
            return false;
        }

        pub fn iterator(hash_map: *const HashMap) Iterator {
            return .{
                .hash_map = hash_map,
                .index = 0,
            };
        }

        pub fn clear(hash_map: *HashMap) void {
            assert(hash_map.count <= hash_map.capacity);
            @memset(hash_map.keys, null);
            @memset(hash_map.values, undefined);
            hash_map.count = 0;
        }

        pub fn get(hash_map: *const HashMap, key: K) ?V {
            assert(hash_map.count <= hash_map.capacity);

            var index = hash_key(key, hash_map.capacity);
            var probes: usize = 0;
            while (probes < hash_map.capacity) : (probes += 1) {
                const found_key = hash_map.keys[index] orelse return null;
                if (std.meta.eql(found_key, key)) {
                    return hash_map.values[index];
                }
                index = (index + 1) % hash_map.capacity;
            }
            return null;
        }

        pub fn contains(hash_map: *const HashMap, key: K) bool {
            assert(hash_map.count <= hash_map.capacity);

            var index = hash_key(key, hash_map.capacity);
            var probes: usize = 0;
            while (probes < hash_map.capacity) : (probes += 1) {
                const found_key = hash_map.keys[index] orelse return false;
                if (std.meta.eql(found_key, key)) {
                    return true;
                }
                index = (index + 1) % hash_map.capacity;
            }
            return false;
        }

        /// Caller must free memory using deinit()
        pub fn clone(hash_map: *const HashMap) Allocator.Error!HashMap {
            assert(hash_map.count <= hash_map.capacity);

            var new_clone = try init_capacity(hash_map.allocator, hash_map.capacity);
            @memcpy(new_clone.keys, hash_map.keys);
            @memcpy(new_clone.values, hash_map.values);
            new_clone.count = hash_map.count;
            new_clone.capacity = hash_map.capacity;

            return new_clone;
        }

        // This grows the hash_map
        fn new(hash_map: *HashMap, new_capacity: usize) Allocator.Error!void {
            assert(new_capacity > 0);
            assert(new_capacity >= hash_map.capacity);

            const old_keys = hash_map.keys;
            const old_values = hash_map.values;

            hash_map.* = try init_capacity(hash_map.allocator, new_capacity);

            // Re-hash the old keys
            for (old_keys, 0..) |maybe_key, i| {
                if (maybe_key) |key| {
                    try hash_map.put(key, old_values[i]);
                }
            }

            hash_map.allocator.free(old_keys);
            hash_map.allocator.free(old_values);
        }

        fn hash_key(key: K, capacity: usize) usize {
            assert(capacity > 0);
            var hasher: std.hash.Wyhash = .init(capacity);
            std.hash.autoHash(&hasher, key);

            return @as(usize, hasher.final()) % capacity;
        }
    };
}

test "init" {
    var hash_map: Hash_Map(u8, bool) = try .init(testing.allocator);
    defer hash_map.deinit();

    try testing.expect(hash_map.capacity > 0);
    try testing.expect(hash_map.count == 0);
}

test "put u8:[]const u8" {
    var hash_map: Hash_Map(u8, []const u8) = try .init(testing.allocator);
    defer hash_map.deinit();

    try hash_map.put(1, "hello");
    try hash_map.put(39, "world");
    try hash_map.put(255, "!");

    try testing.expectEqual(@as(usize, 3), hash_map.count);
}

test "put u8: u64" {
    var hash_map: Hash_Map(u8, u64) = try .init_capacity(testing.allocator, 1);
    defer hash_map.deinit();

    try hash_map.put(99, 1);
    try hash_map.put(2, 39);
    try hash_map.put(3, 255);

    try testing.expectEqual(@as(usize, 3), hash_map.count);
}

test "iterator" {
    var hash_map: Hash_Map(u8, []const u8) = try .init(testing.allocator);
    defer hash_map.deinit();

    try hash_map.put(1, "hello");
    try hash_map.put(39, "world");
    try hash_map.put(255, "!");

    var iter = hash_map.iterator();
    var count: usize = 0;
    while (iter.next()) |entry| {
        try testing.expect(entry.value.len > 0);
        count += 1;
    }
    try testing.expectEqual(hash_map.count, count);
}

test "remove" {
    var hash_map: Hash_Map(u8, []const u8) = try .init(testing.allocator);
    defer hash_map.deinit();

    try hash_map.put(1, "hello");
    try hash_map.put(39, "world");
    try hash_map.put(255, "!");

    try testing.expectEqual(@as(usize, 3), hash_map.count);

    try testing.expect(try hash_map.remove(1));
    try testing.expect(try hash_map.remove(39));

    try testing.expectEqual(@as(usize, 1), hash_map.count);
}

test "clear" {
    var hash_map: Hash_Map(u8, []const u8) = try .init(testing.allocator);
    defer hash_map.deinit();

    try hash_map.put(1, "hello");
    try hash_map.put(39, "world");
    try hash_map.put(255, "!");

    hash_map.clear();
    try testing.expectEqual(@as(usize, 0), hash_map.count);
}

test "get" {
    var hash_map: Hash_Map(u8, []const u8) = try .init(testing.allocator);
    defer hash_map.deinit();

    try hash_map.put(1, "hello");
    try hash_map.put(39, "world");
    try hash_map.put(255, "!");

    try testing.expectEqual("hello", hash_map.get(1).?);
    try testing.expectEqual("world", hash_map.get(39).?);
    try testing.expectEqual("!", hash_map.get(255).?);
}

test "contains" {
    var hash_map: Hash_Map(u8, []const u8) = try .init(testing.allocator);
    defer hash_map.deinit();

    try hash_map.put(1, "hello");
    try hash_map.put(39, "world");
    try hash_map.put(255, "!");

    try testing.expect(hash_map.contains(1));
    try testing.expect(hash_map.contains(39));
    try testing.expect(hash_map.contains(255));
    try testing.expect(!hash_map.contains(0));
}

test "clone" {
    var hash_map: Hash_Map(u8, []const u8) = try .init(testing.allocator);
    defer hash_map.deinit();

    try hash_map.put(1, "hello");
    try hash_map.put(39, "world");
    try hash_map.put(255, "!");

    var new_clone = try hash_map.clone();
    defer new_clone.deinit();

    try testing.expect(new_clone.contains(1));
    try testing.expect(new_clone.contains(39));
    try testing.expectEqual(hash_map.count, new_clone.count);
    try testing.expectEqual(hash_map.capacity, new_clone.capacity);
}

test "complete API" {
    var hash_map: Hash_Map(u8, []const u8) = try .init(testing.allocator);
    defer hash_map.deinit();

    try hash_map.put(1, "hello");
    try hash_map.put(2, "world");

    var cloned_map = try hash_map.clone();
    defer cloned_map.deinit();

    try testing.expectEqual(@as(usize, 2), cloned_map.count);
    try testing.expectEqualSlices(u8, "hello", cloned_map.get(1).?);

    try testing.expect(hash_map.contains(2));

    try testing.expectEqualSlices(u8, "hello", hash_map.get(1).?);
    try testing.expectEqualSlices(u8, "world", hash_map.get(2).?);

    try testing.expect(try hash_map.remove(2));

    var iter = hash_map.iterator();
    while (iter.next()) |entry| {
        try testing.expect(entry.key == 1 and std.mem.eql(u8, "hello", entry.value));
    }
    try testing.expectEqual(@as(usize, 1), hash_map.count);

    hash_map.clear();
    try testing.expectEqual(@as(usize, 0), hash_map.count);
}

test "swarm testing" {
    const HashMap = Hash_Map(u8, []const u8);
    const Model = std.AutoHashMap(u8, []const u8);

    var hash_map: HashMap = try .init(testing.allocator);
    defer hash_map.deinit();

    var model: Model = .init(testing.allocator);
    defer model.deinit();

    var prng: std.Random.DefaultPrng = .init(testing.random_seed);
    const random = prng.random();

    assert(hash_map.count == model.count());
    for (0..1000) |_| {
        const swarm_distribution = random.enumValue(std.meta.DeclEnum(HashMap));
        switch (swarm_distribution) {
            .put => {
                const key = random.int(u8) % 100;
                var value: [500]u8 = undefined;
                random.bytes(&value);

                try hash_map.put(key, &value);
                try model.put(key, &value);

                assert(hash_map.count == model.count());
                assert(hash_map.contains(key) == model.contains(key));
            },
            .remove => {
                assert(try hash_map.remove(0) == model.remove(0));

                const key = random.int(u8) % 100;
                var value: [500]u8 = undefined;
                random.bytes(&value);

                try hash_map.put(key, &value);
                try model.put(key, &value);

                assert(try hash_map.remove(key) == model.remove(key));
            },
            .contains => {
                const key = random.int(u8) % 100;
                var value: [500]u8 = undefined;
                random.bytes(&value);
                assert(hash_map.contains(key) == model.contains(key));

                try hash_map.put(key, &value);
                try model.put(key, &value);
                assert(hash_map.contains(key) == model.contains(key));
            },
            .clear => {
                hash_map.clear();
                model.clearRetainingCapacity();

                assert(hash_map.count == model.count());
                assert(hash_map.count == 0);
            },
            .clone => {
                var hash_map_clone = try hash_map.clone();
                defer hash_map_clone.deinit();

                assert(hash_map_clone.count == hash_map.count);

                var model_iter = model.iterator();
                while (model_iter.next()) |entry| {
                    assert(std.meta.eql(hash_map_clone.get(entry.key_ptr.*), entry.value_ptr.*));
                }
            },
            else => {},
        }
    }
}
