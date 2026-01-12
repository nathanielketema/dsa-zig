//! Data Structures and Algorithms (DSA)
//! - This codebase contains common data structures and algorithms in zig.
//! - It's tailored for beginners learning DSA or for programmers exploring the language. 
//!
//! Enjoy :)

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

// Data Structures
pub const Stack = @import("data-structures/stack.zig").Stack;
pub const Queue = @import("data-structures/queue.zig").Queue;
pub const ArrayList = @import("data-structures/array_list.zig").ArrayList;
pub const HashMap = @import("data-structures/hash_map.zig").HashMap;
pub const Heap = @import("data-structures/heap.zig").Heap;

pub const binary_search_tree = @import("data-structures/binary_search_tree.zig");
pub const BinarySearchTree = binary_search_tree.BinarySearchTree;
pub const BinarySearchTreeWithImplementation = binary_search_tree.BinarySearchTreeWithImplementation;

// Algorithms:
pub const bubble_sort = @import("algorithms/bubble_sort.zig").bubble_sort;
pub const merge_sort = @import("algorithms/merge_sort.zig").merge_sort;
pub const insertion_sort = @import("algorithms/insertion_sort.zig").insertion_sort;
pub const heap_sort = @import("algorithms/heap_sort.zig").heap_sort;
pub const quick_sort = @import("algorithms/quick_sort.zig").quick_sort;
pub const selection_sort = @import("algorithms/selection_sort.zig").selection_sort;

test {
    std.testing.refAllDecls(@This());
}
