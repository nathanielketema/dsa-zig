const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dsa = b.addModule("dsa", .{
        .root_source_file = b.path("src/dsa.zig"),
        .target = target,
        .optimize = optimize,
    });
    dsa.addImport("dsa", dsa); // To make dsa's depend on each other

    const tests = b.addTest(.{
        .root_module = dsa,
    });
    const test_run = b.addRunArtifact(tests);
    const test_step = b.step("test", "Test library");
    test_step.dependOn(&test_run.step);

    const docs = b.addLibrary(.{
        .name = "dvui",
        .root_module = dsa,
    });
    const docs_install = b.addInstallDirectory(.{
        .source_dir = docs.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    const docs_step = b.step("docs", "Build documentation");
    docs_step.dependOn(&docs_install.step);
}
