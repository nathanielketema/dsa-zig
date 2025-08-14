const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

pub fn Stack(comptime T: type) type {
    // You can pick which implementation to expose for the caller
    return StackLinkedList(T);
    //return StackList(T);
}

pub fn StackLinkedList(comptime T: type) type {
    const Node = struct {
        const Self = @This();
        value: T,
        next: ?*Self,
    };

    return struct {
        head: ?*Node,
        /// Number of T items that can be stored
        capacity: u32,
        /// Number of T items that are currently stored
        count: u32,
        allocator: Allocator,

        const Self = @This();

        /// Caller must call deinit() to free up memory after use
        pub fn init(allocator: Allocator, capacity: u32) Self {
            return .{
                .head = null,
                .capacity = capacity,
                .count = 0,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            var current_node = self.head;
            while (current_node) |node| {
                current_node = node.next;
                self.allocator.destroy(node);
            }
        }

        pub fn push(self: *Self, value: T) !void {
            // This is a smart way to ensure if:
            // - count == 0, then self.head must be null, and if
            // - count != 0, then self.head must not be null
            assert((self.count == 0) == (self.head == null));
            assert(self.count < self.capacity);

            const new_node = try self.allocator.create(Node);
            new_node.* = Node{ .value = value, .next = null };

            new_node.next = self.head;
            self.head = new_node;
            self.count += 1;
        }

        pub fn pop(self: *Self) ?T {
            assert((self.count == 0) == (self.head == null));

            // If the stack is empty return null
            const link = self.head orelse return null;
            const value = link.value;

            self.head = link.next;
            self.count -= 1;
            self.allocator.destroy(link);
            return value;
        }

        pub fn peek(self: Self) ?T {
            assert((self.count == 0) == (self.head == null));
            return self.head.value orelse null;
        }

        pub fn empty(self: Self) bool {
            assert((self.count == 0) == (self.head == null));
            return self.head == null;
        }

        pub fn contains(self: Self, needle: T) bool {
            assert((self.count == 0) == (self.head == null));

            var current_node = self.head;
            while (current_node) |node| {
                current_node = node.next;
                if (node.value == needle) return true;
            } else return false;
        }

    };

    // Todo:
    //   - init
    //   - push
    //   - pop
    //   - peek (returns head)
    //   - empty
    //   - contains

}
