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
                .CLA => {
                    self.accumullator = self.memory[memory_address];

                    },
                .ADD => {
                    self.accumullator += self.memory[memory_address];

                    },
                .TAC => {

                    },
                .SFT => {unreachable;},
                .OUT => {unreachable;},
                .STO => {
                    self.memory[memory_address] = self.accumullator;
                },
                .SUB => {unreachable;},
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

test "simple test" {
    var mem: [100] u64 = undefined;

    mem[0] = 198;
    mem[98] = 2;

    mem[1] = 297;
    mem[97] = 4;

    mem[2] = 696;

    mem[3] = 999;

    var cardiac = CARDIAC.new(mem);

    cardiac.run();

    try std.testing.expectEqual(cardiac.memory[96], 6);
}
