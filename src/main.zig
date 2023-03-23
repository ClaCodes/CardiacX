const std = @import("std");

const CARDIAC = struct {
    const Self = @This();
    program_counter: usize,
    accumullator: u64,
    memory: [100] u64,

    pub fn new(memory: [100] u64) CARDIAC {
        return CARDIAC {
            .program_counter = 0,
            .accumullator = 0,
            .memory = memory,
        };
    }

    pub fn run(self: *Self) void {
        running: while(true) {
            const instruction = self.memory[self.program_counter];
            self.program_counter += 1;

            const op_code = @intToEnum(CARDIAC.OPCode, instruction / 100);
            const memory_address = instruction % 100;


            switch (op_code) {
                .INP => {unreachable;},
                .CLA => {self.accumullator = self.memory[memory_address]; },
                .ADD => {self.accumullator += self.memory[memory_address];},
                .TAC => {unreachable;},
                .SFT => {unreachable;},
                .OUT => {unreachable;},
                .STO => {self.memory[memory_address] = self.accumullator;},
                .SUB => {self.accumullator -= self.memory[memory_address];},
                .JMP => {unreachable;},
                .HRS => {break: running;},
            }

        }
    }

    const OPCode = enum {
        INP,
        CLA,
        ADD,
        TAC,
        SFT,
        OUT,
        STO,
        SUB,
        JMP,
        HRS,
    };
};

pub fn main() !void {
}

test "subtract 7 from 32 expect 25" {
    var mem: [100] u64 = undefined;

    // clear and add *98
    mem[0] = 198;
    mem[98] = 32;

    // subtract *97
    mem[1] = 797;
    mem[97] = 7;

    // store *96
    mem[2] = 696;

    //halt
    mem[3] = 999;

    var cardiac = CARDIAC.new(mem);
    cardiac.run();
    try std.testing.expectEqual(cardiac.memory[96], 25);
}

test "add 4 to 2 expect 6" {
    var mem: [100] u64 = undefined;

    // clear and add *98
    mem[0] = 198;
    mem[98] = 2;

    // add *97
    mem[1] = 297;
    mem[97] = 4;

    // store *96
    mem[2] = 696;

    //halt
    mem[3] = 999;

    var cardiac = CARDIAC.new(mem);
    cardiac.run();
    try std.testing.expectEqual(cardiac.memory[96], 6);
}
