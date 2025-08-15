const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const QueueError = error{QueueFull};

pub fn Queue(comptime T: type) type {
    const Node = struct {
        const Self = @This();
        value: T,
        next: ?*Self,
    };

    // Todo:
    // - peek
    // - peek_last
    // - empty
    // - contains
    // - print

    return struct {
        in: ?*Node,
        out: ?*Node,
        capacity: u32,
        count: u32,
        allocator: Allocator,

        const Self = @This();

        /// Caller must call deinit() to free memory
        pub fn init(allocator: Allocator, capacity: u32) Self {
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

            const new_node = self.allocator.create(Node);
            new_node.* = Node{
                .value = value,
                .next = null,
            };

            if (self.in) |in| {
                in.next = new_node;
                in = new_node;
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
    };
}
