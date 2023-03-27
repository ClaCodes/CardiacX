const std = @import("std");

// add files that contain unit-tests (defined using the `test "xyz"` style
// in the list below.
const test_files = .{
    "src/cardiac.zig",
    "zig-asm/asm.zig",
};

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const assembler = b.addExecutable("CardiacAssembler", "zig-asm/asm.zig");
    assembler.setTarget(target);
    assembler.setBuildMode(mode);
    assembler.install();

    const assemble_cmd = assembler.run();
    assemble_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        assemble_cmd.addArgs(args);
    }

    const asm_step = b.step("asm", "Run the assembler");
    asm_step.dependOn(&assemble_cmd.step);

    const exe = b.addExecutable("CardiacX", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run unit tests");
    inline for (test_files) |test_file| {
        const test_build = b.addTest(test_file);
        test_build.setTarget(target);
        test_build.setBuildMode(mode);
        test_step.dependOn(&test_build.step);
    }

}
