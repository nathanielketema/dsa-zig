const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dsa_mod = b.addModule("dsa", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "dsa",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "dsa",
                    .module = dsa_mod,
                },
            },
        }),
    });

    b.installArtifact(exe);

    const exe_stack = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/data-structures/stack.zig"),
            .target = target,
            .optimize = optimize,
        })
    });

    const exe_queue = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/data-structures/queue.zig"),
            .target = target,
            .optimize = optimize,
        })
    });

    const exe_bst_link = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/data-structures/binary_tree_link.zig"),
            .target = target,
            .optimize = optimize,
        })
    });


    const build_steps = .{
        .run_step = b.step("run", "Run main"),
        .test_step = b.step("test", "Test main"),
        .test_stack_step = b.step("test_stack", "Test Stack"),
        .test_queue_step = b.step("test_queue", "Test Queue"),
        .test_bst_link_step = b.step("test_bst_link", "Test Binary Search Tree Linked List"),
    };

    const cmds = .{
        .run_cmd = b.addRunArtifact(exe),
        .test_cmd = b.addRunArtifact(exe),
        .test_stack_cmd = b.addRunArtifact(exe_stack),
        .test_queue_cmd = b.addRunArtifact(exe_queue),
        .test_bst_link_cmd = b.addRunArtifact(exe_bst_link),
    };

    build_steps.run_step.dependOn(&cmds.run_cmd.step);
    build_steps.test_step.dependOn(&cmds.test_cmd.step);
    build_steps.test_stack_step.dependOn(&cmds.test_stack_cmd.step);
    build_steps.test_queue_step.dependOn(&cmds.test_queue_cmd.step);
    build_steps.test_bst_link_step.dependOn(&cmds.test_bst_link_cmd.step);
}
