const std = @import("std");
const Stack = @import("stack.zig").Stack;
const testing = std.testing;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

pub const Implementation = enum {
    linked_list,
};

// The default implementation for now is Linked Lists. I plan to implement this using ArrayList
/// A generic Binary Search Tree
/// - does not accept duplicate values
/// - use BinarySearchTreeWithImplementation for different implementation
pub fn BinarySearchTree(comptime T: type) type {
    return BinarySearchTreeLinkedList(T);
}

/// A generic Binary Search Tree
/// - does not accept duplicate values
/// - user provides which implementation to use
/// - use BinarySearchTree for the default implementation
pub fn BinarySearchTreeWithImplementation(comptime T: type, impl: Implementation) type {
    return switch (impl) {
        .linked_list => BinarySearchTreeLinkedList(T),
    };
}

fn BinarySearchTreeLinkedList(comptime T: type) type {
    return struct {
        allocator: Allocator,
        root: ?*Node,
        count: usize,

        const Self = @This();

        const Node = struct {
            left: ?*Node = null,
            value: T,
            right: ?*Node = null,
        };

        /// Initialize Binary Search Tree
        /// Caller must also free memory by calling deinit_recursive() or deinit_iterative()
        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .root = null,
                .count = 0,
            };
        }

        pub fn deinit_recursive(self: *Self) void {
            if (self.root) |root| {
                deinit_recursive_helper(self.allocator, root);
            }
            self.* = undefined;
        }

        fn deinit_recursive_helper(allocator: Allocator, node: *Node) void {
            if (node.left) |left| {
                deinit_recursive_helper(allocator, left);
            }
            if (node.right) |right| {
                deinit_recursive_helper(allocator, right);
            }

            allocator.destroy(node);
        }

        pub fn deinit_iterative(self: *Self) void {
            if (self.root) |root| {
                var stack: Stack(*Node) = .init(self.allocator);
                defer stack.deinit();

                var visited: std.AutoHashMap(*Node, void) = .init(self.allocator);
                defer visited.deinit();

                stack.push(root) catch unreachable;

                while (!stack.empty()) {
                    const current = stack.peek().?.*;

                    if (visited.contains(current)) {
                        _ = stack.pop();
                        self.allocator.destroy(current);
                        continue;
                    }

                    visited.put(current, {}) catch unreachable;

                    if (current.right) |right| {
                        stack.push(right) catch unreachable;
                    }
                    if (current.left) |left| {
                        stack.push(left) catch unreachable;
                    }
                }
            }
            self.* = undefined;
        }

        /// Returns true if empty
        pub fn empty(self: Self) bool {
            return self.count == 0;
        }

        /// Returns an error if it fails to allocate memory
        pub fn add_recursive(self: *Self, value: T) !void {
            assert((self.count == 0) == (self.root == null));

            self.root = try add_recursive_helper(self.allocator, self.root, value, &self.count);
        }

        fn add_recursive_helper(
            allocator: Allocator,
            root: ?*Node,
            value: T,
            count: *usize,
        ) Allocator.Error!*Node {
            const node = root orelse {
                const new_node = try allocator.create(Node);
                new_node.* = .{ .value = value };
                count.* += 1;
                return new_node;
            };

            switch (std.math.order(value, node.value)) {
                .lt => node.left = try add_recursive_helper(
                    allocator,
                    node.left,
                    value,
                    count,
                ),
                .gt => node.right = try add_recursive_helper(
                    allocator,
                    node.right,
                    value,
                    count,
                ),
                .eq => return node,
            }
            return node;
        }

        /// Returns an error if it fails to allocate memory
        pub fn add_iterative(self: *Self, value: T) Allocator.Error!void {
            const new_node = try self.allocator.create(Node);
            new_node.* = .{ .value = value };

            var current_node = self.root;
            while (current_node) |current| {
                switch (std.math.order(value, current.value)) {
                    .lt => {
                        if (current.left) |left| {
                            current_node = left;
                        } else {
                            self.count += 1;
                            current.left = new_node;
                            return;
                        }
                    },
                    .gt => {
                        if (current.right) |right| {
                            current_node = right;
                        } else {
                            self.count += 1;
                            current.right = new_node;
                            return;
                        }
                    },
                    .eq => {
                        // Because this tree doesn't accept duplicates
                        // - free new_node
                        // - do nothing
                        self.allocator.destroy(new_node);
                        return;
                    },
                }
            } else {
                self.root = new_node;
                self.count += 1;
            }
        }

        /// Returns an error if value can't be found
        pub fn remove_recursive(self: *Self, value: T) !void {
            assert((self.count == 0) == (self.root == null));

            self.root = remove_recursive_helper(self.allocator, self.root, value, &self.count);
        }

        fn remove_recursive_helper(
            allocator: Allocator,
            root: ?*Node,
            value: T,
            count: *usize,
        ) ?*Node {
            const node = root orelse return null;

            switch (std.math.order(value, node.value)) {
                .lt => {
                    node.left = remove_recursive_helper(
                        allocator,
                        node.left,
                        value,
                        count,
                    );
                    return node;
                },
                .gt => {
                    node.right = remove_recursive_helper(
                        allocator,
                        node.right,
                        value,
                        count,
                    );
                    return node;
                },
                .eq => {
                    if (node.left == null and node.right == null) {
                        allocator.destroy(node);
                        count.* -= 1;
                        return null;
                    }

                    if (node.left == null) {
                        const right_child = node.right;
                        allocator.destroy(node);
                        count.* -= 1;
                        return right_child;
                    }

                    if (node.right == null) {
                        const left_child = node.left;
                        allocator.destroy(node);
                        count.* -= 1;
                        return left_child;
                    }

                    const successor = max_node(node.left.?);
                    node.value = successor.value;
                    node.left = remove_recursive_helper(
                        allocator,
                        node.left,
                        successor.value,
                        count,
                    );
                    return node;
                },
            }
        }

        fn max_node(root: *Node) *Node {
            var current_node = root;
            while (current_node.right) |right| {
                current_node = right;
            }

            return current_node;
        }

        pub fn remove_iterative(self: *Self, value: T) void {
            assert((self.count == 0) == (self.root == null));
            if (self.root == null) {
                return;
            }

            const ChildSide = enum { left, right };

            var parent: ?*Node = null;
            var side: ?ChildSide = null;
            var current_node = self.root;

            while (current_node) |current| {
                switch (std.math.order(value, current.value)) {
                    .eq => break,
                    .lt => {
                        side = .left;
                        parent = current;
                        current_node = current.left;
                    },
                    .gt => {
                        side = .right;
                        parent = current;
                        current_node = current.right;
                    },
                }
            }

            const node = current_node orelse return;

            if (node.left == null and node.right == null) {
                if (parent) |p| {
                    switch (side.?) {
                        .left => p.left = null,
                        .right => p.right = null,
                    }
                } else {
                    self.root = null;
                }
                self.allocator.destroy(node);
            } else if (node.left == null or node.right == null) {
                const child = node.left orelse node.right.?;
                if (parent) |p| {
                    switch (side.?) {
                        .left => p.left = child,
                        .right => p.right = child,
                    }
                } else {
                    self.root = child;
                }
                self.allocator.destroy(node);
            } else {
                var successor_parent = node;
                var successor = node.left.?;
                while (successor.right) |right| {
                    successor_parent = successor;
                    successor = right;
                }

                node.value = successor.value;
                if (successor_parent == node) {
                    successor_parent.left = successor.left;
                } else {
                    successor_parent.right = successor.left;
                }
                self.allocator.destroy(successor);
            }

            self.count -= 1;
        }

        pub fn pre_order_recursive(self: Self, list: *std.ArrayList(T)) !void {
            try pre_order_recursive_helper(self.allocator, self.root, list);
        }

        fn pre_order_recursive_helper(
            allocator: Allocator,
            root: ?*Node,
            list: *std.ArrayList(T),
        ) !void {
            const node = root orelse return;

            try list.append(allocator, node.value);
            try pre_order_recursive_helper(allocator, node.left, list);
            try pre_order_recursive_helper(allocator, node.right, list);
        }

        pub fn pre_order_iterative(self: Self, list: *std.ArrayList(T)) !void {
            var stack: Stack(?*Node) = .init(self.allocator);
            defer stack.deinit();

            try stack.push(self.root);
            while (!stack.empty()) {
                const item = stack.pop().?;

                if (item) |node| {
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

        pub fn in_order_recursive(self: Self, list: *std.ArrayList(T)) !void {
            try in_order_recursive_helper(self.allocator, self.root, list);
        }

        fn in_order_recursive_helper(
            allocator: Allocator,
            root: ?*Node,
            list: *std.ArrayList(T),
        ) !void {
            const node = root orelse return;

            try in_order_recursive_helper(allocator, node.left, list);
            try list.append(allocator, node.value);
            try in_order_recursive_helper(allocator, node.right, list);
        }

        pub fn in_order_iterative(self: Self, list: *std.ArrayList(T)) !void {
            var stack: Stack(?*Node) = .init(self.allocator);
            defer stack.deinit();


            var current_node = self.root;
            while (current_node != null or !stack.empty()) {
                while (current_node) |current| {
                    try stack.push(current);
                    current_node = current.left;
                }

                const item = stack.pop().?;
                if (item) |node| {
                    try list.append(self.allocator, node.value);
                    current_node = node.right;
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
            const node = root orelse return;

            try post_order_recursive_helper(allocator, node.left, list);
            try post_order_recursive_helper(allocator, node.right, list);
            try list.append(allocator, node.value);
        }

        pub fn post_order_iterative(self: Self, list: *std.ArrayList(T)) !void {
            const root = self.root orelse return;
            var stack: Stack(*Node) = .init(self.allocator);
            defer stack.deinit();

            var visited: std.AutoHashMap(*Node, bool) = .init(self.allocator);
            defer visited.deinit();

            try stack.push(root);
            while (!stack.empty()) {
                const current_node = stack.peek().?.*;
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

        pub fn search_recursive(self: Self, needle: T) bool {
            return search_recursive_helper(self.root, needle);
        }

        fn search_recursive_helper(root: ?*Node, needle: T) bool {
            const node = root orelse return false;

            return switch (std.math.order(needle, node.value)) {
                .lt => search_recursive_helper(node.left, needle),
                .gt => search_recursive_helper(node.right, needle),
                .eq => true,
            };
        }

        pub fn search_iterative(self: Self, needle: T) bool {
            var current_node = self.root;
            while (current_node) |node| {
                switch (std.math.order(needle, node.value)) {
                    .lt => current_node = node.left,
                    .gt => current_node = node.right,
                    .eq => return true,
                }
            }
            return false;
        }

        pub fn height_recursive(self: Self) usize {
            return height_recursive_helper(self.root);
        }

        fn height_recursive_helper(root: ?*Node) usize {
            const node = root orelse return 0;
            return 1 + @max(
                height_recursive_helper(node.left),
                height_recursive_helper(node.right),
            );
        }

        pub fn height_iterative(self: Self) usize {
            const root = self.root orelse return 0;

            const StackItem = struct {
                node: *Node,
                depth: usize,
            };

            var stack: Stack(StackItem) = .init(self.allocator);
            defer stack.deinit();

            stack.push(.{
                .node = root,
                .depth = 1,
            }) catch unreachable;

            var max_height: usize = 0;
            while (!stack.empty()) {
                const item = stack.pop().?;
                max_height = @max(max_height, item.depth);

                if (item.node.right) |right| {
                    stack.push(.{
                        .node = right,
                        .depth = item.depth + 1,
                    }) catch unreachable;
                }

                if (item.node.left) |left| {
                    stack.push(.{
                        .node = left,
                        .depth = item.depth + 1,
                    }) catch unreachable;
                }
            }

            return max_height;
        }
    };
}

test "binary search tree (linked list) operations: recursive" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var bst: BinarySearchTreeWithImplementation(u8, .linked_list) = .init(allocator);
    defer bst.deinit_recursive();

    try testing.expect(bst.empty());
    try bst.add_recursive(8);
    try bst.add_recursive(8);
    try bst.add_recursive(6);
    try bst.add_recursive(2);

    try testing.expectEqual(8, bst.root.?.value);

    try bst.add_recursive(4);
    try bst.add_recursive(9);
    try bst.add_recursive(1);

    try testing.expect(!bst.empty());

    try bst.add_recursive(7);
    try bst.add_recursive(5);
    try bst.add_recursive(3);
    try bst.add_recursive(40);
    try bst.add_recursive(10);
    try bst.add_recursive(100);

    try testing.expectEqual(bst.height_recursive(), 5);

    try testing.expect(bst.search_recursive(7));
    try bst.remove_recursive(7);

    try testing.expect(bst.search_recursive(6));
    try bst.remove_recursive(6);

    try testing.expect(bst.search_recursive(9));
    try bst.remove_recursive(9);

    try testing.expect(bst.search_recursive(8));
    try bst.remove_recursive(8);
}

test "binary search tree (linked list) operations: iterative" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var bst: BinarySearchTreeWithImplementation(u8, .linked_list) = .init(allocator);
    defer bst.deinit_iterative();

    try testing.expect(bst.empty());

    try bst.add_iterative(8);
    try bst.add_iterative(8);
    try bst.add_iterative(6);
    try bst.add_iterative(2);

    try testing.expectEqual(8, bst.root.?.value);

    try bst.add_iterative(4);
    try bst.add_iterative(9);
    try bst.add_iterative(1);

    try testing.expect(!bst.empty());

    try bst.add_iterative(7);
    try bst.add_iterative(5);
    try bst.add_iterative(3);
    try bst.add_iterative(40);
    try bst.add_iterative(10);
    try bst.add_iterative(100);

    try testing.expectEqual(bst.height_iterative(), 5);

    try testing.expect(bst.search_iterative(7));
    bst.remove_iterative(7);

    try testing.expect(bst.search_iterative(6));
    bst.remove_iterative(6);

    try testing.expect(bst.search_iterative(9));
    bst.remove_iterative(9);

    try testing.expect(bst.search_iterative(8));
    bst.remove_iterative(8);
}

test "swarm testing recursive against iterative approach" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var bst_iterative: BinarySearchTreeWithImplementation(u8, .linked_list) = .init(allocator);
    defer bst_iterative.deinit_iterative();

    var bst_recursive: BinarySearchTreeWithImplementation(u8, .linked_list) = .init(allocator);
    defer bst_recursive.deinit_recursive();

    const N = 1_000;
    var prng = std.Random.DefaultPrng.init(std.testing.random_seed);
    const random = prng.random();

    const Operation = enum {
        add,
        remove,
        search,
    };

    for (0..N) |_| {
        const operation = random.enumValue(Operation);
        const value = random.int(u8);

        switch (operation) {
            .add => {
                try bst_recursive.add_recursive(value);
                try bst_iterative.add_iterative(value);

                try testing.expectEqual(bst_iterative.count, bst_recursive.count);
            },
            .remove => {
                const result_recursive = bst_recursive.remove_recursive(value);
                const result_iterative = bst_iterative.remove_iterative(value);

                if (result_recursive) {
                    result_iterative;
                } else |err| {
                    try testing.expectError(err, result_iterative);
                }

                try testing.expectEqual(bst_iterative.count, bst_recursive.count);
            },
            .search => {
                const found_recursive = bst_recursive.search_recursive(value);
                const found_iterative = bst_iterative.search_iterative(value);

                try testing.expectEqual(found_recursive, found_iterative);
            },
        }
    }
}

test "binary search tree (linked lists) traversals: recursive" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var bst: BinarySearchTreeWithImplementation(u8, .linked_list) = .init(allocator);
    defer bst.deinit_recursive();

    try bst.add_recursive(8);
    try bst.add_recursive(6);
    try bst.add_recursive(2);
    try bst.add_recursive(4);
    try bst.add_recursive(9);
    try bst.add_recursive(1);
    try bst.add_recursive(7);
    try bst.add_recursive(5);
    try bst.add_recursive(3);
    try bst.add_recursive(40);
    try bst.add_recursive(10);
    try bst.add_recursive(100);

    var list = try std.ArrayList(u8).initCapacity(allocator, bst.count);
    defer list.deinit(allocator);

    try bst.pre_order_recursive(&list);
    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 8, 6, 2, 1, 4, 3, 5, 7, 9, 40, 10, 100 },
        list.items,
    );

    list.clearRetainingCapacity();
    try bst.in_order_recursive(&list);
    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 40, 100 },
        list.items,
    );

    list.clearRetainingCapacity();
    try bst.post_order_recursive(&list);
    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 1, 3, 5, 4, 2, 7, 6, 10, 100, 40, 9, 8 },
        list.items,
    );
}

test "binary search tree (linked lists) traversals: iterative" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var bst: BinarySearchTreeWithImplementation(u8, .linked_list) = .init(allocator);
    defer bst.deinit_iterative();

    try bst.add_iterative(8);
    try bst.add_iterative(6);
    try bst.add_iterative(2);
    try bst.add_iterative(4);
    try bst.add_iterative(9);
    try bst.add_iterative(1);
    try bst.add_iterative(7);
    try bst.add_iterative(5);
    try bst.add_iterative(3);
    try bst.add_iterative(40);
    try bst.add_iterative(10);
    try bst.add_iterative(100);

    var list = try std.ArrayList(u8).initCapacity(allocator, bst.count);
    defer list.deinit(allocator);

    try bst.pre_order_iterative(&list);
    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 8, 6, 2, 1, 4, 3, 5, 7, 9, 40, 10, 100 },
        list.items,
    );

    list.clearRetainingCapacity();
    try bst.in_order_iterative(&list);
    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 40, 100 },
        list.items,
    );

    list.clearRetainingCapacity();
    try bst.post_order_iterative(&list);
    try testing.expectEqualSlices(
        u8,
        &[_]u8{ 1, 3, 5, 4, 2, 7, 6, 10, 100, 40, 9, 8 },
        list.items,
    );
}
