const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dsa_module = b.addModule("dsa", .{
        .root_source_file = b.path("src/dsa.zig"),
        .target = target,
        .optimize = optimize,
    });

    dsa_module.addImport("dsa", dsa_module);

    const docs_module = b.createModule(.{
        .root_source_file = b.path("src/dsa.zig"),
        .target = target,
        .optimize = optimize,
    });
    docs_module.addImport("dsa", docs_module);

    const lib = b.addLibrary(.{
        .name = "dsa",
        .linkage = .static,
        .root_module = docs_module,
    });

    const install_docs = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(&install_docs.step);

    const tests = b.addTest(.{
        .root_module = dsa_module,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_tests.step);
}
