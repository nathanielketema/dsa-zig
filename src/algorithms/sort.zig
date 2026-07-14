pub const bubble = @import("sort_bubble.zig").bubble_sort;
pub const merge = @import("sort_merge.zig").merge_sort;
pub const insertion = @import("sort_insertion.zig").insertion_sort;
pub const heap = @import("sort_heap.zig").heap_sort;
pub const quick = @import("sort_quick.zig").quick_sort;
pub const selection = @import("sort_selection.zig").selection_sort;

test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
}
