const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;

const StackError = error{FullStack};

pub fn Stack(comptime T: type) type {
    return struct {
        allocator: Allocator,
        head: ?*Node,
        capacity: usize,
        count: usize,

        const Self = @This();

        const Node = struct {
            value: T,
            next: ?*Node,
        };

        /// Caller must call deinit() to free up memory after use
        pub fn init(allocator: Allocator, capacity: usize) Self {
            return .{
                .allocator = allocator,
                .head = null,
                .capacity = capacity,
                .count = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            var current_node = self.head;
            while (current_node) |node| {
                current_node = node.next;
                self.allocator.destroy(node);
            }
        }

        pub fn push(self: *Self, value: T) (StackError || Allocator.Error)!void {
            // This is a smart way to ensure if:
            // - count == 0, then self.head must be null, and if
            // - count != 0, then self.head must not be null
            assert((self.count == 0) == (self.head == null));

            if (self.count >= self.capacity) {
                return StackError.FullStack;
            }

            const new_node = try self.allocator.create(Node);
            new_node.* = Node{
                .value = value,
                .next = self.head,
            };

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

        pub fn peek(self: Self) ?*const T {
            assert((self.count == 0) == (self.head == null));
            if (self.head) |head| {
                return &head.value;
            } 
            return null;
        }

        pub fn empty(self: Self) bool {
            assert((self.count == 0) == (self.head == null));
            return self.count == 0;
        }

        pub fn contains(self: Self, needle: T) bool {
            assert((self.count == 0) == (self.head == null));

            var current_node = self.head;
            while (current_node) |node| : (current_node = node.next){
                if (std.meta.eql(needle, node.value)) return true;
            } 
            return false;
        }
    };
}

test "test stack operations" {
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

    try stack.push(5);
    try stack.push(6);
    try stack.push(7);
    try stack.push(8);
    try stack.push(9);
    try stack.push(10);

    try testing.expect(stack.count == stack.capacity);
}

test "push beyond capacity" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var stack: Stack(u8) = .init(allocator, 2);
    defer stack.deinit();

    try stack.push(1);
    try stack.push(2);
    try testing.expectError(StackError.FullStack, stack.push(3));
}

test "capacity zero stack" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var stack: Stack(u8) = .init(allocator, 0);
    defer stack.deinit();

    try testing.expectError(StackError.FullStack, stack.push(1));
}
