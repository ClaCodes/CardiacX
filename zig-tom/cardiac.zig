// https://en.wikipedia.org/wiki/CARDboard_Illustrative_Aid_to_Computation
// https://www.cs.drexel.edu/~bls96/museum/cardiac.html
// https://www.cs.drexel.edu/~bls96/museum/cardsim.html

const std = @import("std");

const out_fn = *const fn (value: i16) void;
const inp_fn = *const fn () i16;

const OpCode = enum(usize) {
    INP = 0,
    CLA = 1,
    ADD = 2,
    TAC = 3,
    SFT = 4,
    OUT = 5,
    STO = 6,
    SUB = 7,
    JMP = 8,
    HRS = 9,
};

pub fn cardiac(memory: *[100]i16, pc_start: usize, inp: inp_fn, out: out_fn) void {
    var acc: i16 = 0;
    var pc: usize = pc_start;

    memory[0] = 1;

    while (true) {
        const instruction: u16 = @intCast(u16, memory[pc]);
        const opcode: OpCode = @intToEnum(OpCode, instruction / 100);
        const address: usize = instruction % 100;

        pc += 1;

        switch (opcode) {
            OpCode.INP => memory[address] = @rem(inp(), 1000),
            OpCode.CLA => acc = memory[address],
            OpCode.ADD => acc = acc + memory[address],
            OpCode.TAC => {
                if (acc < 0) {
                    pc = address;
                }
            },
            OpCode.SFT => {
                const l: u16 = @intCast(u16, address) / 10;
                const r: u16 = @intCast(u16, address) % 10;
                acc = @divFloor(acc * @intCast(i16, std.math.pow(u16, 10, l)), @intCast(i16, std.math.pow(u16, 10, r)));
            },
            OpCode.OUT => out(memory[address]),
            OpCode.STO => {
                if ((address != 0) and (address != 99)) {
                    memory[address] = acc;
                }
            },
            OpCode.SUB => acc = acc - memory[address],
            OpCode.JMP => {
                memory[99] = 800 + @intCast(i16, pc);
                pc = address;
            },
            OpCode.HRS => {
                pc = address;
                break;
            },
        }
        acc = @rem(acc, 1000);
    }
}

fn out_null(_: i16) void {}

fn out_stdout(value: i16) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("{}\n", .{value}) catch {};
}

fn inp_666() i16 {
    return 666;
}

fn inp_stdin() i16 {
    const stdin = std.io.getStdIn().reader();
    var buffer: [8]u8 = undefined;
    if (stdin.readUntilDelimiterOrEof(&buffer, '\n') catch null) |line| {
        return std.fmt.parseInt(i16, line, 10) catch 0;
    } else {
        return 0;
    }
}

fn make_instruction(opcode: OpCode, address: usize) i16 {
    return (@intCast(i16, @enumToInt(opcode)) * 100) + @intCast(i16, address);
}

fn program_demo(memory: *[100]i16) void {
    // code - main

    memory[1] = make_instruction(OpCode.CLA, 20);
    memory[2] = make_instruction(OpCode.ADD, 21);
    memory[3] = make_instruction(OpCode.SFT, 21); // * 100 / 10
    memory[4] = make_instruction(OpCode.STO, 23);
    memory[5] = make_instruction(OpCode.OUT, 23);
    memory[6] = make_instruction(OpCode.JMP, 10); // jump to subroutine
    memory[7] = make_instruction(OpCode.HRS, 1);

    // code - subroutine

    memory[10] = make_instruction(OpCode.INP, 24);
    memory[11] = make_instruction(OpCode.OUT, 24);
    memory[12] = make_instruction(OpCode.CLA, 99); // load return address
    memory[13] = make_instruction(OpCode.STO, 14); // store return address in next cell
    memory[14] = 0; // will be filled by previous command

    // data - main

    memory[20] = -3;
    memory[21] = -6;
    memory[23] = 999;

    // data - subroutine

    memory[24] = 888;
}

pub fn main() !void {
    var memory: [100]i16 = undefined;
    cardiac(&memory, 0, inp_stdin, out_stdout);
}

test "make_instruction" {
    try std.testing.expectEqual(make_instruction(OpCode.CLA, 23), 123);
}

test "program_demo" {
    var memory: [100]i16 = undefined;
    program_demo(&memory);

    try std.testing.expectEqual(memory[23], 999);
    try std.testing.expectEqual(memory[24], 888);

    cardiac(&memory, 1, inp_666, out_null);

    try std.testing.expectEqual(memory[23], -90);
    try std.testing.expectEqual(memory[24], 666);
}
