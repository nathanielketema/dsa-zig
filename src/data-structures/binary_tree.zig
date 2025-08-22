const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

pub fn BinarySearchTree(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            left: ?*Node,
            value: T,
            right: ?*Node,
        };

        root: ?*Node,
        count: u32,
        capacity: u32, // think about it, might have to remove
        allocator: Allocator,

        pub fn init(allocator: Allocator, capacity: u32) Self {
            return .{
                .root = null,
                .count = 0,
                .capacity = capacity,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            _ = self;
        }

        pub fn inorder(self: Self) void {
            assert((self.count == 0) == (self.root == null));

            if (self.root) |root| {
                self.inorder(root.left);
                std.debug.print("{d}\n", .{root.value});
                self.inorder(root.right);
            } else {
                return;
            }
        }

        pub fn empty(self: Self) bool {
            assert((self.count == 0) == (self.root == null));
            return self.count == 0;
        }
    };
}
