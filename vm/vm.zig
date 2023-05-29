const std = @import("std");

export fn version() i32 {
    return 1;
}

export fn assemble(startAddress: usize, endAddress: *usize, memory: *[100]i16, inPointer: [*]const u8, inLength: usize) i32 {
    for (0..memory.len) |i| {
        memory[i] = @intCast(i16, i);
    }

    const in = inPointer[0..inLength];
    memory[0] = @intCast(i16, in.len);
    endAddress.* = startAddress;

    const result: i32 = if (startAddress == 0) 1 else 0;

    // TODO call function

    return result;
}

export fn run(memory: *[100]i16, pc_start: usize) i32 {
    memory[0] = @intCast(i16, pc_start);

    // TODO call function

    return 1;
}
