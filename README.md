# Useful data structures and algorithms (DSA)

This library contains useful data structures and algorithms
in [zig](https://ziglang.org/).

## Start

```console
zig fetch --save git+https://github.com/nathanielketema/dsa-zig.git
```

Then, add this to your `build.zig`:

```zig
const dsa = b.dependency("dsa_zig", .{
    .target = target,
    .optimize = optimize,
});
// ...
exe.root_module.addImport("dsa", dsa.module("dsa"));
```

Finally, import and start using it:

```zig
const dsa = @import("dsa");
```

## Documentation

This library comes with its own documentation page.

To access the docs:

```console
zig build docs
```

## Example

Using a Stack:

```zig
const std = @import("std");
const assert = std.debug.assert;

const dsa = @import("dsa");
const Stack = dsa.Stack;

pub fn main(init: std.process.Init) !void {
    var stack: Stack(u8) = .init(init.gpa);
    defer stack.deinit();

    try stack.push(1);
    try stack.push(2);
    try stack.push(3);

    _ = stack.pop();
}
```
