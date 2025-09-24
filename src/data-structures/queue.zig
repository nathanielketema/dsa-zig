const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const QueueError = error{QueueFull};

pub fn Queue(comptime T: type) type {
    return struct {
        in: ?*Node,
        out: ?*Node,
        capacity: usize,
        count: usize,
        allocator: Allocator,

        const Self = @This();
        const Node = struct {
            value: T,
            next: ?*Node,
        };

        /// Caller must call deinit() to free memory
        pub fn init(allocator: Allocator, capacity: usize) Self {
            return .{
                .in = null,
                .out = null,
                .capacity = capacity,
                .count = 0,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            var current_node = self.out;
            while (current_node) |out| {
                current_node = out.next;
                self.allocator.destroy(out);
            }
        }

        pub fn push(self: *Self, value: T) !void {
            // An if and only if condtion for three elements
            assert((self.count == 0) == (self.in == null) and
                (self.in == null) == (self.out == null));

            if (!(self.count < self.capacity)) {
                return QueueError.QueueFull;
            }

            const new_node = try self.allocator.create(Node);
            new_node.* = Node{
                .value = value,
                .next = null,
            };

            if (self.in) |*in| {
                in.*.next = new_node;
                in.* = new_node;
            } else {
                self.in = new_node;
                self.out = new_node;
            }

            self.count += 1;
        }

        pub fn pop(self: *Self) ?T {
            assert((self.count == 0) == (self.in == null) and
                (self.in == null) == (self.out == null));

            const link = self.out orelse return null;
            defer self.allocator.destroy(link);
            const value = link.value;

            self.out = link.next;
            self.count -= 1;
            return value;
        }

        pub fn peek(self: Self) ?T {
            assert((self.count == 0) == (self.in == null) and
                (self.in == null) == (self.out == null));

            if (self.out) |out| {
                return out.value;
            } else return null;
        }

        pub fn peek_last(self: Self) ?T {
            assert((self.count == 0) == (self.in == null) and
                (self.in == null) == (self.out == null));

            if (self.in) |in| {
                return in.value;
            } else return null;
        }

        pub fn empty(self: Self) bool {
            assert((self.count == 0) == (self.in == null) and
                (self.in == null) == (self.out == null));
            return self.count == 0;
        }

        pub fn contains(self: Self, needle: T) bool {
            assert((self.count == 0) == (self.in == null) and
                (self.in == null) == (self.out == null));

            var current_node = self.out;
            while (current_node) |node| {
                current_node = node.next;
                if (node.value == needle) return true;
            } else return false;
        }

        pub fn print(self: Self) void {
            assert((self.count == 0) == (self.in == null) and
                (self.in == null) == (self.out == null));

            std.debug.print(
                \\out
                \\ | 
                \\ v
                \\
            , .{});

            var current_node = self.out;
            while (current_node) |node| {
                current_node = node.next;
                std.debug.print(" {d} -> ", .{node.value});
            }

            std.debug.print("null <- in\n\n", .{});
        }
    };
}

test "test queue" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var queue = Queue(u8).init(allocator, 10);
    defer queue.deinit();

    try testing.expect(queue.capacity == 10);
    try testing.expect(queue.count == 0);
    try testing.expect(queue.empty());
    try testing.expect(queue.pop() == null);
    try testing.expect(queue.peek() == null);
    try testing.expect(queue.peek_last() == null);

    try queue.push(1);
    try queue.push(2);
    try queue.push(3);
    try queue.push(4);
    try queue.push(5);
    try queue.push(6);

    try testing.expect(queue.count == 6);
    try testing.expect(queue.contains(6));
    try testing.expectEqual(queue.peek(), 1);
    try testing.expectEqual(queue.peek_last().?, 6);

    try testing.expectEqual(queue.pop().?, 1);
    try testing.expectEqual(queue.pop().?, 2);

    try testing.expectEqual(queue.peek().?, 3);
    try testing.expectEqual(queue.peek_last().?, 6);
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
