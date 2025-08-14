const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

pub fn Stack(comptime T: type) type {
    // You can pick any of the implementations below to expose for the caller
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
        capacity: u32,
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
            new_node.* = Node{
                .value = value,
                .next = null,
            };

            new_node.next = self.head;
            self.head = new_node;
            self.count += 1;
        }

        pub fn pop(self: *Self) ?T {
            assert((self.count == 0) == (self.head == null));

            const link = self.head orelse return null;
            defer self.allocator.destroy(link);

            self.head = link.next;
            self.count -= 1;
            return link.value;
        }

        pub fn peek(self: Self) ?T {
            assert((self.count == 0) == (self.head == null));
            if (self.head) |head| {
                return head.value;
            } else return null;
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

        pub fn print(self: Self) void {
            assert((self.count == 0) == (self.head == null));

            std.debug.print(
                \\head 
                \\ |
                \\ v
                \\
            , .{});
            var current_node = self.head;
            while (current_node) |node| {
                current_node = node.next;
                std.debug.print(" {d} -> ", .{node.value});
            }
            std.debug.print("null\n\n", .{});
        }
    };
}

const testing = std.testing;

test "test 1" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var stack = Stack(u8).init(allocator, 10);
    defer stack.deinit();

    try testing.expect(stack.capacity == 10);
    try testing.expect(stack.count == 0);
    try testing.expect(stack.empty());
    try testing.expect(stack.pop() == null);
    try testing.expect(stack.peek() == null);

    try stack.push(1);
    try stack.push(2);
    try stack.push(3);
    try stack.push(4);
    try stack.push(5);
    try stack.push(6);

    stack.print();

    try testing.expect(stack.count == 6);
    try testing.expect(stack.contains(6));
    try testing.expectEqual(stack.peek().?, 6);

    try testing.expectEqual(stack.pop().?, 6);
    try testing.expectEqual(stack.pop().?, 5);

    try testing.expectEqual(stack.peek().?, 4);
    try testing.expect(stack.count == 4);

    try testing.expect(stack.contains(4));
    try testing.expect(!stack.contains(6));
    try testing.expect(!stack.empty());

    stack.print();

    try stack.push(5);
    try stack.push(6);
    try stack.push(7);
    try stack.push(8);
    try stack.push(9);
    try stack.push(10);

    try testing.expect(stack.count == stack.capacity);

    stack.print();
}
