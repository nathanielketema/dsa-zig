const std = @import("std");
const dsa = @import("dsa");

const print = std.debug.print;
const testing = std.testing;
const assert = std.debug.assert;

const Stack = dsa.Stack;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var stack = Stack(u8).init(allocator, 10);
    defer stack.deinit();

    try stack.push(1);
    try stack.push(2);
    try stack.push(3);
    try stack.push(4);
    try stack.push(5);
    try stack.push(6);

    stack.print();
}
