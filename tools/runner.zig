const std = @import("std");

const assembler = @import("asm.zig");

const os = std.os;
const fs = std.fs;
const Allocator = std.mem.Allocator;

const builtin = @import("builtin");
const native_os = builtin.target.os.tag;

pub fn main() !void {
    // example 1:
    // zig build runner -- cardiac_programs /.../.../zig-out/bin/CardiacX
    // CardiacRunner cardiac_programs /.../.../zig-out/bin/CardiacX
    //
    // example 2:
    // zig run runner.zig -- ../cardiac_programs ../go-tom/main

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    try run_on_files(args[2..], args[1], 3, allocator);
}

fn run_on_files(invoke_child: []const []const u8, programs_directory: []const u8, start_address: usize, allocator: Allocator) !void {
    const files = try alloc_dir_content(programs_directory, allocator);
    defer free_dir_content(files, allocator);

    std.debug.print("================================================================================\n", .{});
    std.debug.print("Testing command: {s}\n", .{invoke_child});
    std.debug.print("Testing directory: {s}\n", .{programs_directory});
    std.debug.print("================================================================================\n", .{});

    for (files.items) |file| {
        std.debug.print("Testing file: {s}\n", .{file});

        const program = try assemble_file(file, start_address, allocator);
        defer program.deinit();

        var bootable = std.ArrayList(i16).init(allocator);
        defer bootable.deinit();

        try bootable.append(2); // load to 2
        try bootable.append(800); // jump to 0
        for (program.items[start_address..], start_address..) |instruction, address| {
            try bootable.append(@intCast(i16, address));
            try bootable.append(instruction);
        }
        try bootable.append(2); // load to 2
        try bootable.append(800 + @intCast(i16, start_address)); // jump to start

        try invoke_with_timeout(invoke_child, bootable.items, allocator);
        std.debug.print("================================================================================\n", .{});
    }
}

fn alloc_dir_content(programs_directory: []const u8, allocator: Allocator) !std.ArrayList([]const u8) {
    var dir = try fs.cwd().openIterableDir(programs_directory, .{});
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var path_list = std.ArrayList([]const u8).init(allocator);

    while (try walker.next()) |entry| {
        const path = try fs.path.join(allocator, &[_][]const u8{ programs_directory, entry.path });
        try path_list.append(path);
    }
    return path_list;
}

fn free_dir_content(files: std.ArrayList([]const u8), allocator: Allocator) void {
    for (files.items) |file| {
        allocator.free(file);
    }
    files.deinit();
}

fn assemble_file(path: []const u8, start_address: usize, allocator: Allocator) !std.ArrayList(i16) {
    var program = std.ArrayList(i16).init(allocator);
    const mode: os.mode_t = if (native_os == .windows) 0 else 0o666;

    var buf: [1024]u8 = undefined;

    const fd = try os.open(path, os.O.RDWR, mode);
    defer os.close(fd);

    const b = try os.read(fd, &buf);

    var program_array: [100]i16 = undefined;
    var end: usize = 0;

    try assembler.assemble(start_address, &end, &program_array, buf[0 .. b - 1], allocator);

    try program.appendSlice(program_array[0..end]);
    return program;
}

fn invoke_with_timeout(invoke_child: []const []const u8, program: []const i16, allocator: Allocator) !void {
    var arrlist = std.ArrayList([]const u8).init(allocator);
    defer arrlist.deinit();

    // todo timeout configurable
    // todo find solution without relying on gnu core utils
    try arrlist.append("timeout");
    try arrlist.append("8");
    try arrlist.appendSlice(invoke_child);

    std.debug.print("Invoking Child Process: {s}\n", .{arrlist.items});

    var child = std.ChildProcess.init(arrlist.items, allocator);
    child.stdin_behavior = std.ChildProcess.StdIo.Pipe;
    child.stdout_behavior = std.ChildProcess.StdIo.Pipe;
    child.stderr_behavior = std.ChildProcess.StdIo.Pipe;

    try child.spawn();
    for (program) |instruction| {
        _ = try child.stdin.?.writer().print("{}\n", .{instruction});
    }

    // wait 1 s
    // todo is ther a wait to get 'child.wait' to work with pipes?
    std.time.sleep(1_000_000_000);

    var stdout = std.ArrayList(u8).init(allocator);
    defer stdout.deinit();

    var stderr = std.ArrayList(u8).init(allocator);
    defer stderr.deinit();

    try child.collectOutput(&stdout, &stderr, 1024);

    const res = try child.kill();

    var success = false;
    switch (res) {
        .Exited => {
            success = (res.Exited == 0);
            std.debug.print("Exit:{}\n", .{res.Exited});
        },
        .Signal => std.debug.print("Signal:{}\n", .{res.Signal}),
        .Stopped => std.debug.print("Stopped:{}\n", .{res.Stopped}),
        .Unknown => std.debug.print("Unknown:{}\n", .{res.Unknown}),
    }

    std.debug.print("Std Out:\n\"{s}\"\n", .{stdout.items});
    std.debug.print("Std Err:\n\"{s}\"\n", .{stderr.items});
}
