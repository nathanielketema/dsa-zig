# Data Structures and Algorithms (DSA) using zig

I'm trying to learn the zig way of implementing common data structures and
algorithms in [zig](https://github.com/ziglang/zig.git). Any advice is much 
appreciated.

## Setup

To use these data structures and algorithms in your own codebase:

1. Add this as a dependency in your `build.zig.zon` file:

```console
zig fetch --save git+https://github.com/nathanielketema/dsa-zig.git
```

2.  Next step is to add it to your `build.zig`:

```zig
const dsa = b.dependency("dsa_zig", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("dsa", dsa.module("dsa"));
```

3. Finally, you can use it by importing it to your code base:

```zig
const dsa = @import("dsa");
```

### Example

Using a Stack:

```zig
const std = @import("std");
const dsa = @import("dsa");
const Stack = dsa.Stack;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var stack = Stack(u8).init(allocator);
    defer stack.deinit();

    try stack.push(1);
    try stack.push(2);
    try stack.push(3);

    _ = stack.pop();
}
```
