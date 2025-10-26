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
            .name = "bubble",
            .path = "src/algorithms/bubble_sort.zig",
            .description = "Test Bubble Sort",
        },
        .{
            .name = "merge",
            .path = "src/algorithms/merge_sort.zig",
            .description = "Test Merge Sort",
        },
        .{
            .name = "insertion",
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
    };

    const test_all_step = b.step("test", "Run all tests");

    for (test_files) |test_file| {
        const test_exe = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(test_file.path),
                .target = target,
                .optimize = optimize,
            }),
        });

        const run_all_test = b.addRunArtifact(test_exe);
        test_all_step.dependOn(&run_all_test.step);

        const step_name = b.fmt("test_{s}", .{test_file.name});
        const test_step = b.step(step_name, test_file.description);
        const run_test = b.addRunArtifact(test_exe);
        test_step.dependOn(&run_test.step);
    }
}
