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
        count: usize,
        capacity: usize,
        allocator: Allocator,

        // Todo:
        // - add
        //   - recursive
        //   - iterative
        // - remove
        //   - recursive
        //   - iterative
        // - empty
        // - search
        //   - recursive
        //   - iterative
        // - height
        //   - recursive
        //   - iterative
        // - preorder
        //   - recursive
        //   - iterative
        // - inorder
        //   - recursive
        //   - iterative
        // - postorder
        //   - recursive
        //   - iterative

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

        pub fn deinit(self: *Self) void {
            _ = self;
        }

        pub fn empty(self: Self) bool {
            assert((self.count == 0) == (self.root == null));
            return self.root == null;
        }
    };
}
