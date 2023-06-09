const std = @import("std");

// add files that contain unit-tests (defined using the `test "xyz"` style
// in the list below.
const test_files = .{
    "zig-cla/main.zig",
    "tools/runner.zig",
    "tools/asm.zig",
};

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "CardiacX",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "zig-cla/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const asm_exe = b.addExecutable(.{
        .name = "CardiacAssembler",
        .root_source_file = .{ .path = "tools/asm.zig" },
        .target = target,
        .optimize = optimize,
    });

    const runner_exe = b.addExecutable(.{
        .name = "CardiacRunner",
        .root_source_file = .{ .path = "tools/runner.zig" },
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    exe.install();
    asm_exe.install();
    runner_exe.install();

    // This *creates* a RunStep in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = exe.run();
    const asm_cmd = asm_exe.run();
    const runner_cmd = runner_exe.run();

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());
    asm_cmd.step.dependOn(b.getInstallStep());
    runner_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
        asm_cmd.addArgs(args);
        runner_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    const asm_step = b.step("asm", "Run the assembler");
    asm_step.dependOn(&asm_cmd.step);
    const runner_step = b.step("runner", "Run over a directory to assemble and test");
    runner_step.dependOn(&runner_cmd.step);


    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    inline for (test_files) |test_file| {
        // Creates a step for unit testing.
        const test_build = b.addTest(.{
            .root_source_file = .{ .path = test_file },
            .target = target,
            .optimize = optimize,
        });
        test_step.dependOn(&test_build.run().step);
    }
}
