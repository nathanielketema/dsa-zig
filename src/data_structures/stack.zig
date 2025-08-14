const std = @import("std");
const assert = std.debug.assert;

pub fn Stack(comptime T: type) type {
    // You can pick which implementation to expose for the caller
    return StackLinkedList(T);
    //return StackList(T);
}

fn StackLinkedList(comptime T: type) type {
    const Node = struct {
        const Self = @This();
        items: T,
        next: ?*Self,
    };

    return struct {
        head: ?Node,
        /// Number of T items that can be stored
        capacity: u32,
        /// Number of T items that are currently stored
        count: u32,
    };

    // Todo:
    //   - init
    //   - push
    //   - pop
    //   - peek (returns head)
    //   - empty
    //   - contains

}
