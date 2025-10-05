const std = @import("std");
const Stack = @import("stack.zig").Stack;
const testing = std.testing;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const BinarySearchTreeError = error{ FullTree, NotFound };

pub fn BinarySearchTree(comptime T: type) type {
    return struct {
        allocator: Allocator,
        root: ?*Node,
        count: usize,
        capacity: usize,

        const Self = @This();

        const Node = struct {
            left: ?*Node = null,
            value: T,
            right: ?*Node = null,
        };

        // Todo:
        // - remove
        //   - iterative
        // - height
        //   - recursive
        //   - iterative

        /// Initialize your Binary Search Tree with an optional capacity
        /// - If capacity is not provided, the default would set the capacity
        ///   to 100 T elements
        /// Caller must also free memory by calling deinit()
        pub fn init(allocator: Allocator, capacity: ?u32) Self {
            return .{
                .allocator = allocator,
                .root = null,
                .count = 0,
                .capacity = capacity orelse 100,
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
                return BinarySearchTreeError.FullTree;
            }

            self.root = try add_recursive_helper(self.allocator, self.root, value);
            self.count += 1;
        }

        fn add_recursive_helper(allocator: Allocator, root: ?*Node, value: T) !?*Node {
            if (root) |node| {
                if (value < node.value) {
                    node.left = try add_recursive_helper(allocator, node.left, value);
                } else if (value > node.value) {
                    node.right = try add_recursive_helper(allocator, node.right, value);
                }
                return node;
            } else {
                const new_node = try allocator.create(Node);
                new_node.* = .{ .value = value };
                return new_node;
            }
        }

        pub fn add_iterative(self: *Self, value: T) !void {
            const new_node = try self.allocator.create(Node);
            new_node.* = .{ .value = value };

            if (self.root) |root| {
                var current = root;
                while (true) {
                    switch (std.math.order(value, current.value)) {
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
                var stack: Stack(?*Node) = .init(self.allocator, self.capacity);
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
                var stack: Stack(?*Node) = .init(self.allocator, self.capacity);
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

        pub fn post_order_iterative_better(self: Self, list: *std.ArrayList(T)) !void {
            if (self.root) |_| {
                var stack: Stack(*Node) = .init(self.allocator, self.capacity);
                defer stack.deinit();

                var current: ?*Node = self.root;
                var last_visited: ?*Node = null;

                while (current != null or !stack.empty()) {
                    while (current) |curr| {
                        try stack.push(curr);
                        current = curr.left;
                    }

                    const top = stack.peek().?;

                    if (top.right) |right| {
                        if (last_visited != right) {
                            current = right;
                            continue;
                        }
                    }

                    try list.append(self.allocator, top.value);
                    last_visited = stack.pop();
                }
            }
        }

        pub fn post_order_iterative(self: Self, list: *std.ArrayList(T)) !void {
            if (self.root) |root| {
                var stack: Stack(*Node) = .init(self.allocator, self.capacity);
                defer stack.deinit();

                var visited: std.AutoHashMap(*Node, bool) = .init(self.allocator);
                defer visited.deinit();

                try stack.push(root);

                while (!stack.empty()) {
                    const current_node = stack.peek().?;

                    if (visited.get(current_node)) |_| {
                        try list.append(self.allocator, stack.pop().?.value);
                        continue;
                    }
                    try visited.put(current_node, true);

                    if (current_node.right) |right| {
                        try stack.push(right);
                    }
                    if (current_node.left) |left| {
                        try stack.push(left);
                    }
                }
            }
        }

        pub fn search_recursive(self: *Self, needle: T) bool {
            assert((self.count == 0) == (self.root == null));

            return search_recursive_helper(self.root, needle);
        }

        fn search_recursive_helper(root: ?*Node, needle: T) bool {
            if (root) |node| {
                if (needle == node.value) {
                    return true;
                } else if (needle < node.value) {
                    return search_recursive_helper(node.left, needle);
                } else if (needle > node.value) {
                    return search_recursive_helper(node.right, needle);
                }
            }

            return false;
        }

        pub fn search_iterative(self: *Self, needle: T) bool {
            assert((self.count == 0) == (self.root == null));

            var current_node = self.root;
            while (current_node) |node| {
                if (needle == node.value) {
                    return true;
                } else if (needle < node.value) {
                    current_node = node.left;
                } else if (needle > node.value) {
                    current_node = node.right;
                }
            }

            return false;
        }

        pub fn remove_recursive(self: *Self, value: T) !void {
            assert((self.count == 0) == (self.root == null));

            self.root = try remove_recursive_helper(self.allocator, self.root, value);
            self.count -= 1;
        }

        fn remove_recursive_helper(allocator: Allocator, root: ?*Node, value: T) !?*Node {
            if (root) |node| {
                if (value == node.value) {
                    if (node.left == null and node.right == null) {
                        allocator.destroy(node);
                        return null;
                    }
                    if (node.left == null) {
                        const temp = node.right;
                        allocator.destroy(node);
                        return temp;
                    } else if (node.right == null) {
                        const temp = node.left;
                        allocator.destroy(node);
                        return temp;
                    }

                    std.mem.swap(T, &node.value, max_node(node.left.?));
                    node.left = try remove_recursive_helper(allocator, node.left, value);
                    return node;
                } else if (value < node.value) {
                    node.left = try remove_recursive_helper(allocator, node.left, value);
                    return node;
                } else if (value > node.value) {
                    node.right = try remove_recursive_helper(allocator, node.right, value);
                    return node;
                }
            }

            return BinarySearchTreeError.NotFound;
        }

        fn max_node(root: *Node) *T {
            if (root.right) |right| {
                return max_node(right);
            } else {
                return &root.value;
            }
        }

        pub fn remove_iterative(self: *Self, value: T) !void {
            assert((self.count == 0) == (self.root == null));

            var current_node = self.root;
            while (current_node) |node| {
                if (value == node.value) {
                    if (node.left == null and node.right == null) {
                        self.allocator.destroy(node);
                        return;
                    } else if (node.left == null) {
                        node.right = node.right.?.right;
                    } else if (node.right == null) {
                    }
                } else if (value < node.value) {
                    current_node = node.right;
                } else if (value > node.value) {
                    current_node = node.right;
                }
            }

            return BinarySearchTreeError.NotFound;
        }
    };
}

test "binary search tree operations" {
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

    try testing.expect(binary_tree.search_recursive(7));
    try binary_tree.remove_recursive(7);
    try testing.expect(!binary_tree.search_iterative(7));

    try testing.expect(binary_tree.search_recursive(6));
    try binary_tree.remove_recursive(6);
    try testing.expect(!binary_tree.search_iterative(6));

    try testing.expect(binary_tree.search_recursive(9));
    try binary_tree.remove_recursive(9);
    try testing.expect(!binary_tree.search_iterative(9));

    try testing.expect(binary_tree.search_recursive(8));
    try binary_tree.remove_recursive(8);
    try testing.expect(!binary_tree.search_iterative(8));
}

test "binary search tree traversals" {
    var gpa: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer gpa.deinit();
    const allocator = gpa.allocator();

    var binary_tree = BinarySearchTree(u8).init(allocator, null);

    try binary_tree.add_recursive(8);
    try binary_tree.add_recursive(6);
    try binary_tree.add_recursive(2);
    try binary_tree.add_recursive(4);
    try binary_tree.add_recursive(9);
    try binary_tree.add_recursive(1);
    try binary_tree.add_iterative(7);
    try binary_tree.add_iterative(5);
    try binary_tree.add_iterative(3);
    try binary_tree.add_iterative(40);
    try binary_tree.add_iterative(10);
    try binary_tree.add_iterative(100);

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

    list.clearRetainingCapacity();
    try binary_tree.post_order_iterative_better(&list);
    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 1, 3, 5, 4, 2, 7, 6, 10, 100, 40, 9, 8 },
        list.items,
    );
}
