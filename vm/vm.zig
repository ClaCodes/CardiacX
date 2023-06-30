const std = @import("std");

const emulator = @import("cardiac.zig");
const assembler = @import("asm.zig");

export fn version() i32 {
    return 1;
}

export fn assemble(startAddress: usize, endAddress: *usize, memory: *[100]i16, inPointer: [*]const u8, inLength: usize) i32 {
    var buffer: [4096]u8 = undefined;
    // std.heap.page_allocator does not work with wasm
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const in = inPointer[0..inLength];

    var result: i32 = 1;
    assembler.assemble(startAddress, endAddress, memory, in, allocator) catch {
        result = 0;
    };
    return result;
}

export fn run(memory: *[100]i16, pc_start: usize) i32 {
    emulator.cardiac(memory, pc_start, emulator.inp_666, emulator.out_null);
    return 1;
}
