const std = @import("std");
const dsa = @import("dsa");

const print = std.debug.print;
const testing = std.testing;
const assert = std.debug.assert;

const Stack = dsa.Stack;
const Queue = dsa.Queue;

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

    print("Stack: \n", .{});
    stack.print();

    var queue = Queue(u8).init(allocator, 10);
    defer queue.deinit();

    try queue.push(1);
    try queue.push(2);
    try queue.push(3);
    try queue.push(4);
    try queue.push(5);
    try queue.push(6);

    print("Queue: \n", .{});
    queue.print();

    var list = [_]u8{ 3, 1, 7, 4, 2 };
    print("unsorted: {any}\n", .{list});

    dsa.bubble_sort(u8, &list);

    print("sorted: {any}\n", .{list});
}
