const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const troy = b.addModule("troy", .{
        .root_source_file = b.path("src/zTroy.zig"),
    });

    const object = b.addObject(.{
        .name = "object",
        .root_source_file = b.path("src/zTroy.zig"),
        .target = target,
        .optimize = optimize,
    });

    const docs_step = b.step("docs", "Generate docs");

    const docs_install = b.addInstallDirectory(.{
        .source_dir = object.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    docs_step.dependOn(&docs_install.step);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });

    unit_tests.root_module.addImport("troy", troy);

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
