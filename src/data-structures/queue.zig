const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const QueueError = error{QueueFull};

pub fn Queue(comptime T: type) type {
    return struct {
        allocator: Allocator,
        in: ?*Node,
        out: ?*Node,
        capacity: usize,
        count: usize,

        const Self = @This();

        const Node = struct {
            value: T,
            next: ?*Node,
        };

        /// Caller must call deinit() to free memory
        pub fn init(allocator: Allocator, capacity: usize) Self {
            return .{
                .allocator = allocator,
                .in = null,
                .out = null,
                .capacity = capacity,
                .count = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            var current_node = self.out;
            while (current_node) |out| {
                current_node = out.next;
                self.allocator.destroy(out);
            }
        }

        pub fn push(self: *Self, value: T) (QueueError || Allocator.Error)!void {
            // An if and only if condtion for three elements
            assert((self.count == 0) == (self.in == null));
            assert((self.count == 0) == (self.out == null));

            if (self.count >= self.capacity) {
                return QueueError.QueueFull;
            }

            const new_node = try self.allocator.create(Node);
            new_node.* = Node{
                .value = value,
                .next = null,
            };

            if (self.in) |in_node| {
                in_node.next = new_node;
                self.in = new_node;
            } else {
                self.in = new_node;
                self.out = new_node;
            }

            self.count += 1;
            assert(self.count <= self.capacity);
        }

        pub fn pop(self: *Self) ?T {
            assert((self.count == 0) == (self.in == null));
            assert((self.count == 0) == (self.out == null));

            const link = self.out orelse return null;
            defer self.allocator.destroy(link);

            self.out = link.next;
            self.count -= 1;

            if (self.count == 0) {
                self.in = null;
            }

            return link.value;
        }

        pub fn peek(self: Self) ?*const T {
            assert((self.count == 0) == (self.in == null));
            assert((self.count == 0) == (self.out == null));

            if (self.out) |out| {
                return &out.value;
            } 
            return null;
        }

        pub fn peek_last(self: Self) ?*const T {
            assert((self.count == 0) == (self.in == null));
            assert((self.count == 0) == (self.out == null));

            if (self.in) |in| {
                return &in.value;
            } 
            return null;
        }

        pub fn empty(self: Self) bool {
            assert((self.count == 0) == (self.in == null));
            assert((self.count == 0) == (self.out == null));
            return self.count == 0;
        }

        pub fn contains(self: Self, needle: T) bool {
            assert((self.count == 0) == (self.in == null));
            assert((self.count == 0) == (self.out == null));

            var current_node = self.out;
            while (current_node) |node| : (current_node = node.next) {
                if (std.meta.eql(needle, node.value)) return true;
            } 
            return false;
        }
    };
}

test "test queue" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var queue: Queue(u8) = .init(allocator, 10);
    defer queue.deinit();

    try testing.expect(queue.capacity == 10);
    try testing.expect(queue.count == 0);
    try testing.expect(queue.empty());
    try testing.expect(queue.pop() == null);
    try testing.expect(queue.peek() == null);
    try testing.expect(queue.peek_last() == null);

    try queue.push(1);
    try queue.push(2);
    try testing.expect(queue.in.?.value == 2);

    try queue.push(3);
    try queue.push(4);
    try queue.push(5);
    try queue.push(6);

    try testing.expect(queue.count == 6);
    try testing.expect(queue.contains(6));
    try testing.expectEqual(queue.peek().?.*, 1);
    try testing.expectEqual(queue.peek_last().?.*, 6);

    try testing.expectEqual(queue.pop().?, 1);
    try testing.expectEqual(queue.pop().?, 2);

    try testing.expectEqual(queue.peek().?.*, 3);
    try testing.expectEqual(queue.peek_last().?.*, 6);
    try testing.expect(queue.count == 4);

    try testing.expect(!queue.contains(1));
    try testing.expect(queue.contains(4));
    try testing.expect(queue.contains(6));
    try testing.expect(!queue.empty());

    try queue.push(5);
    try queue.push(6);
    try queue.push(7);
    try queue.push(8);
    try queue.push(9);
    try queue.push(10);

    try testing.expect(queue.count == queue.capacity);
}

test "push beyond capacity" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var queue: Queue(u8) = .init(allocator, 2);
    defer queue.deinit();

    try queue.push(1);
    try queue.push(2);
    try testing.expectError(QueueError.QueueFull, queue.push(3));
}

test "empty then refill" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var queue: Queue(u8) = .init(allocator, 5);
    defer queue.deinit();

    try queue.push(1);
    try queue.push(2);
    
    _ = queue.pop();
    _ = queue.pop();
    
    try testing.expect(queue.empty());
    try testing.expect(queue.in == null);
    try testing.expect(queue.out == null);
    
    // Should work fine after emptying
    try queue.push(3);
    try testing.expectEqual(queue.peek().?.*, 3);
}
