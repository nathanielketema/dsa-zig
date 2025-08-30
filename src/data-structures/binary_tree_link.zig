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
        //   - iterative
        // - inorder
        //   - iterative
        // - postorder
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

        pub fn deinit_recursive(self: *Self) void {
            if (self.root) |root| {
                deinit_recursive_helper(self.allocator, root);
            } else {
                self.* = undefined;
            }
        }

        fn deinit_recursive_helper(allocator: Allocator, root: *Node) void {
            if (root.left) |left| {
                deinit_recursive_helper(allocator, left);
            } else {
                if (root.right) |right| {
                    deinit_recursive_helper(allocator, right);
                }
            }

            if (root.left == null and root.right == null) {
                allocator.destroy(root);
                return;
            }
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

        pub fn add_iterative(self: *Self, item: T) !void {
            const new_node = try self.allocator.create(Node);
            new_node.* = .{ .value = item };

            if (self.root) |root| {
                var current = root;
                while (true) {
                    switch (std.math.order(item, current.value)) {
                        .lt => {
                            if (current.left) |left| {
                                current = left;
                            } else {
                                current.left = new_node;
                                self.count += 1;
                                return;
                            }
                        },
                        .gt => {
                            if (current.right) |right| {
                                current = right;
                            } else {
                                current.right = new_node;
                                self.count += 1;
                                return;
                            }
                        },
                        .eq => {
                            // Because this tree doesn't accept duplicates
                            // - do nothing
                            // - free new_node
                            self.allocator.destroy(new_node);
                            return;
                        },
                    }
                }
            } else {
                self.root = new_node;
                self.count += 1;
                return;
            }
        }

        pub fn empty(self: Self) bool {
            assert((self.count == 0) == (self.root == null));
            return self.root == null;
        }

        pub fn pre_order_recursive(self: Self, list: *std.ArrayList(T)) !void {
            try pre_order_recursive_helper(self.allocator, self.root, list);
        }

        fn pre_order_recursive_helper(
            allocator: Allocator,
            root: ?*Node,
            list: *std.ArrayList(T),
        ) !void {
            if (root) |node| {
                try list.append(allocator, node.value);
                try pre_order_recursive_helper(allocator, node.left, list);
                try pre_order_recursive_helper(allocator, node.right, list);
            }
        }

        pub fn pre_order_iterative(self: Self, list: *std.ArrayList(T)) !void {
            if (self.root) |_| {
                var stack = Stack(?*Node).init(self.allocator, self.capacity);
                defer stack.deinit();

                try stack.push(self.root);

                while (stack.pop()) |pop| {
                    if (pop) |node| {
                        try list.append(self.allocator, node.value);
                        if (node.right) |right| {
                            try stack.push(right);
                        }
                        if (node.left) |left| {
                            try stack.push(left);
                        }
                    }
                }
            }
        }

        pub fn in_order_recursive(self: Self, list: *std.ArrayList(T)) !void {
            try in_order_recursive_helper(self.allocator, self.root, list);
        }

        fn in_order_recursive_helper(
            allocator: Allocator,
            root: ?*Node,
            list: *std.ArrayList(T),
        ) !void {
            if (root) |node| {
                try in_order_recursive_helper(allocator, node.left, list);
                try list.append(allocator, node.value);
                try in_order_recursive_helper(allocator, node.right, list);
            }
        }

        pub fn in_order_iterative(self: Self, list: *std.ArrayList(T)) !void {
            if (self.root) |_| {
                var stack = Stack(?*Node).init(self.allocator, self.capacity);
                defer stack.deinit();

                var current_node = self.root;

                while (current_node != null or stack.count > 0) {
                    while (current_node) |current| {
                        try stack.push(current);
                        current_node = current.left;
                    }
                    if (stack.pop()) |pop| {
                        if (pop) |node| {
                            try list.append(self.allocator, node.value);
                            current_node = node.right;
                        }
                    }
                }
            }
        }

        pub fn post_order_recursive(self: Self, list: *std.ArrayList(T)) !void {
            try post_order_recursive_helper(self.allocator, self.root, list);
        }

        fn post_order_recursive_helper(
            allocator: Allocator,
            root: ?*Node,
            list: *std.ArrayList(T),
        ) !void {
            if (root) |node| {
                try post_order_recursive_helper(allocator, node.left, list);
                try post_order_recursive_helper(allocator, node.right, list);
                try list.append(allocator, node.value);
            }
        }

        pub fn post_order_iterative(self: Self, list: *std.ArrayList(T)) !void {
            if (self.root) |_| {
                var stack = Stack(?*Node).init(self.allocator, self.capacity);
                defer stack.deinit();

                try stack.push(self.root);

                while (stack.pop()) |pop| {
                    if (pop) |node| {
                        try list.append(self.allocator, node.value);
                        if (node.right) |right| {
                            try stack.push(right);
                        }

                        if (node.left) |left| {
                            try stack.push(left);
                        }
                    }
                }
            }
        }
    };
}

test "binary search" {
    var gpa: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer gpa.deinit();
    const allocator = gpa.allocator();

    var binary_tree = BinarySearchTree(u8).init(allocator, null);
    //defer binary_tree.deinit_recursive();
    //defer binary_tree.deinit_iterative();

    try testing.expect(binary_tree.empty());

    try binary_tree.add_recursive(8);
    try binary_tree.add_recursive(6);
    try binary_tree.add_recursive(2);
    try binary_tree.add_recursive(4);
    try binary_tree.add_recursive(9);
    try binary_tree.add_recursive(1);

    try testing.expect(!binary_tree.empty());

    try binary_tree.add_iterative(7);
    try binary_tree.add_iterative(5);
    try binary_tree.add_iterative(3);
    try binary_tree.add_iterative(40);
    try binary_tree.add_iterative(10);
    try binary_tree.add_iterative(100);

    // Tree traversal
    var list = try std.ArrayList(u8).initCapacity(allocator, binary_tree.capacity);
    defer list.deinit(allocator);

    try binary_tree.pre_order_recursive(&list);
    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 8, 6, 2, 1, 4, 3, 5, 7, 9, 40, 10, 100 },
        list.items,
    );

    list.clearRetainingCapacity();
    try binary_tree.pre_order_iterative(&list);
    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 8, 6, 2, 1, 4, 3, 5, 7, 9, 40, 10, 100 },
        list.items,
    );

    list.clearRetainingCapacity();
    try binary_tree.in_order_recursive(&list);
    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 40, 100 },
        list.items,
    );

    list.clearRetainingCapacity();
    try binary_tree.in_order_iterative(&list);
    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 40, 100 },
        list.items,
    );

    list.clearRetainingCapacity();
    try binary_tree.post_order_recursive(&list);
    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 1, 3, 5, 4, 2, 7, 6, 10, 100, 40, 9, 8 },
        list.items,
    );

    list.clearRetainingCapacity();
    try binary_tree.post_order_iterative(&list);
    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 1, 3, 5, 4, 2, 7, 6, 10, 100, 40, 9, 8 },
        list.items,
    );
}
