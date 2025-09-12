const std = @import("std");
const Stack = @import("stack.zig").Stack;
const testing = std.testing;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const BinaryTreeError = error{FullTree};

pub fn BinarySearchTree(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            left: ?*Node = null,
            value: T,
            right: ?*Node = null,
        };

        root: ?*Node,
        count: usize,
        capacity: usize,
        allocator: Allocator,

        /// Initialize your Binary Search Tree with an optional capacity
        /// - If capacity is not provided, the default would set the capacity
        ///   to 100 T elements
        /// Caller must also free memory by calling deinit()
        pub fn init(allocator: Allocator, capacity: ?u32) Self {
            return .{
                .root = null,
                .count = 0,
                .capacity = capacity orelse 100,
                .allocator = allocator,
            };
        }

        pub fn add_recursive(self: *Self, value: T) !void {
            assert((self.count == 0) == (self.root == null));

            if (!(self.count < self.capacity)) {
                return BinaryTreeError.FullTree;
            }

            self.root = try add_recursive_helper(self.allocator, self.root, value);
            self.count += 1;
        }

        fn add_recursive_helper(allocator: Allocator, root: ?*Node, item: T) !?*Node {
            if (root) |node| {
                if (item < node.value) {
                    node.left = try add_recursive_helper(allocator, node.left, item);
                } else if (item > node.value) {
                    node.right = try add_recursive_helper(allocator, node.right, item);
                }
                return node;
            } else {
                const new_node = try allocator.create(Node);
                new_node.* = .{ .value = item };
                return new_node;
            }
        }
