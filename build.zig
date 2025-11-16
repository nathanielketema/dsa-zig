const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("dsa", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const TestFile = struct {
        name: []const u8,
        path: []const u8,
        description: []const u8,
    };

    const test_files = [_]TestFile{
        .{
            .name = "stack",
            .path = "src/data-structures/stack.zig",
            .description = "Test Stack",
        },
        .{
            .name = "queue",
            .path = "src/data-structures/queue.zig",
            .description = "Test Queue",
        },
        .{
            .name = "bst",
            .path = "src/data-structures/binary_search_tree.zig",
            .description = "Test Binary Search Tree",
        },
        .{
            .name = "bubble_sort",
            .path = "src/algorithms/bubble_sort.zig",
            .description = "Test Bubble Sort",
        },
        .{
            .name = "merge_sort",
            .path = "src/algorithms/merge_sort.zig",
            .description = "Test Merge Sort",
        },
        .{
            .name = "insertion_sort",
            .path = "src/algorithms/insertion_sort.zig",
            .description = "Test Insertion Sort",
        },
        .{
            .name = "array_list",
            .path = "src/data-structures/array_list.zig",
            .description = "Test Array List",
        },
        .{
            .name = "hash_map",
            .path = "src/data-structures/hash_map.zig",
            .description = "Test Hash Map",
        },
        .{
            .name = "heap",
            .path = "src/data-structures/heap.zig",
            .description = "Test Heap",
        },
        .{
            .name = "heap_sort",
            .path = "src/algorithms/heap_sort.zig",
            .description = "Test Heap Sort",
        },
        .{
            .name = "quick_sort",
            .path = "src/algorithms/quick_sort.zig",
            .description = "Test Quick Sort",
        },
        .{
            .name = "selection_sort",
            .path = "src/algorithms/selection_sort.zig",
            .description = "Test Selection Sort",
        },
    };

    const test_all_step = b.step("test", "Run all tests");

    for (test_files) |test_file| {
        const heap_module = b.addModule("heap", .{
            .root_source_file = b.path("src/data-structures/heap.zig"),
            .target = target,
            .optimize = optimize,
        });

        const root_module = b.createModule(.{
            .root_source_file = b.path(test_file.path),
            .target = target,
            .optimize = optimize,
        });

        if (std.mem.eql(u8, test_file.name, "heap_sort")) {
            root_module.addImport("heap", heap_module);
        }

        const test_exe = b.addTest(.{
            .root_module = root_module,
        });

        const run_all_test = b.addRunArtifact(test_exe);
        test_all_step.dependOn(&run_all_test.step);

        const step_name = b.fmt("test_{s}", .{test_file.name});
        const test_step = b.step(step_name, test_file.description);
        const run_test = b.addRunArtifact(test_exe);
        test_step.dependOn(&run_test.step);
    }
}
