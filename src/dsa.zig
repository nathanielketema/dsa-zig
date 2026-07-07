// TODO(#1): add custom format functions to make printing nicer

// Data Structures
pub const Stack = @import("data-structures/stack.zig").Stack;
pub const Queue = @import("data-structures/queue.zig").Queue;
pub const ArrayList = @import("data-structures/array_list.zig").ArrayList;
pub const HashMap = @import("data-structures/hash_map.zig").HashMap;
pub const Heap = @import("data-structures/heap.zig").Heap;

// TODO: fix this api to the below
// pub const BinarySearchTree = @import("data-structures/binary_search_tree.zig");
pub const binary_search_tree = @import("data-structures/binary_search_tree.zig");
pub const BinarySearchTree = binary_search_tree.BinarySearchTree;
pub const BinarySearchTreeWithImplementation = binary_search_tree.BinarySearchTreeWithImplementation;

// Algorithms:
pub const sort = @import("algorithms/sort.zig");

test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
}
