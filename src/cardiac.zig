const std = @import("std");
const BusDevice = @import("bus.zig").BusDevice;
const IODevice = @import("bus.zig").IODevice;
const StorageDevice = @import("bus.zig").StorageDevice;

pub const Cardiac = struct {
    program_counter: usize,
    accumullator: u64,
    memory: [100] u64,
    bus_device: ?*BusDevice,

    pub fn new(bus_device: ?*BusDevice) Cardiac {
        var cardiac = Cardiac {
            .program_counter = undefined,
            .accumullator = undefined,
            .memory = .{undefined}**100,
            .bus_device = bus_device,
        };
        cardiac.reset();
        return cardiac;
    }

    pub fn reset(self: *@This()) void {
        self.program_counter = 0;
        self.accumullator = 0;
        self.memory = .{0}**100;
        self.memory[0] = 1;
    }

    pub fn flash(self: *@This(), program: []const u64) !void {
        for (program) |byte, index| {
            if(byte > 999) return Cardiac.Error.InvalidProgram;
            if(index < self.memory.len) self.memory[index] = byte;
        }
    }

    pub fn readTo(self: *@This(), memory_address: u64) !void {
        if(self.bus_device) |device| {
            self.memory[memory_address] = try device.read();
        } else {
            return Cardiac.Error.EndOfInput;
        }
    }

    pub fn writeFrom(self: *@This(), memory_address: u64) !void {
        if(self.bus_device) |device| {
            try device.write(self.memory[memory_address]);
        } else {
            return Cardiac.Error.BusError;
        }
    }

    pub fn step(self: *@This()) !void {
        const instruction = self.memory[self.program_counter];
        self.program_counter += 1;

        const op_code = @intToEnum(Cardiac.OPCode, instruction / 100);
        const memory_address = instruction % 100;

        switch (op_code) {
            .INP => {try self.readTo(memory_address);},
            .CLA => {self.accumullator = self.memory[memory_address]; },
            .ADD => {self.accumullator += self.memory[memory_address];},
            .TAC => {unreachable;},
            .SFT => {unreachable;},
            .OUT => {try self.writeFrom(memory_address);},
            .STO => {self.memory[memory_address] = self.accumullator;},
            .SUB => {self.accumullator -= self.memory[memory_address];},
            .JMP => {self.program_counter = memory_address;},
            .HRS => {return Cardiac.Error.Halted;},
        }
    }

    pub fn run(self: *@This()) void {
        while(true) {
            self.step() catch break;
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

    pub const Error = error {
        EndOfInput,
        BusError,
        Halted,
        InvalidProgram,
    };
};


test "invalid instruction expect error" {
    const program =  [_]u64{
        1098, // 0: invalid instruction accepted range -999 to 999
    };

    var cardiac = Cardiac.new(null);
    const flashable = cardiac.flash(&program);

    try std.testing.expectError(Cardiac.Error.InvalidProgram, flashable);
}

test "write output" {
    const program =  [_]u64{
        503, // 0: write from 3
        504, // 1: write from 4
        505, // 2: write from 5
         39, // 3: data
         32, // 4: data
          7, // 5: data
    };

    var write_buffer:[2]u64 = undefined;

    var storage: BusDevice = .{.storage = StorageDevice.new(&[_]u64{}, write_buffer[0..2])};

    var cardiac = Cardiac.new(&storage);
    var cardiac_no_input_deivce = Cardiac.new(null);

    try cardiac.flash(&program);
    try cardiac_no_input_deivce.flash(&program);

    try cardiac.step(); // write from 3
    try cardiac.step(); // write from 4
    const final_step = cardiac.step(); // attempt to write from 5

    try std.testing.expectEqual(write_buffer[0], 39);
    try std.testing.expectEqual(write_buffer[1], 32);
    try std.testing.expectError(BusDevice.Error.WriteError, final_step);

    const read_without_input = cardiac_no_input_deivce.step();

    try std.testing.expectError(Cardiac.Error.BusError, read_without_input);
}

test "bootstrap program expect execute correct addition" {
    // after reset program counter points to 0 which contains instruction
    // 001 = read input to 1
    // this gives us control over the second instruction to execute
    // we establish a read-loop to place instructions in memory
    // finally we will break the read-loop and hand-off control to the actual program

    const bootable_program =  [_]u64{
        // establish read loop
          2, // read    to  2
        800, // jump    to  0

        // read in program
          3, // read    to  3
        108, // load  from  8    will be at 3
          4, // read    to  4
        209, // add   from  9    will be at 4
          5, // read    to  5
        610, // store   to 10    will be at 5
          6, // read    to  6
        510, // write from 10    will be at 6
          7, // read    to  7
        999, // halt             will be at 7
          8, // read    to  8
        123, // data             will be at 8
          9, // read    to  9
        181, // data             will be at 9

        // hand off control to program at 3
          2, // read    to  2
        803, // jmp     to  3    will be at 2
    };

    var out_buffer:[1]u64 = undefined;

    var storage:BusDevice = .{.storage = StorageDevice.new(&bootable_program, &out_buffer)};

    var cardiac = Cardiac.new(&storage);
    cardiac.run();

    try std.testing.expectEqual(out_buffer[0], 304);

}

test "reset should immediately halt again" {
    var cardiac = Cardiac.new(null);
    const step_after_reset = cardiac.step(); // read to 1
    try std.testing.expectError(Cardiac.Error.EndOfInput, step_after_reset);
}

test "read input" {
    const program =  [_]u64{
          2, // 0: read to 2
        800, // 1: jump to 0
    };

    var values = [_]u64{23, 334};

    var storage:BusDevice = .{.storage = StorageDevice.new(&values, &[_]u64{})};

    var cardiac = Cardiac.new(&storage);
    var cardiac_no_input_deivce = Cardiac.new(null);

    try cardiac.flash(&program);
    try cardiac_no_input_deivce.flash(&program);

    try cardiac.step(); // read to 2
    try std.testing.expectEqual(cardiac.memory[2], 23);
    try cardiac.step(); // jmp
    try cardiac.step(); // read to 2
    try std.testing.expectEqual(cardiac.memory[2], 334);
    try cardiac.step(); // jmp
    const final_step = cardiac.step(); // attempt read but end of input

    try std.testing.expectError(BusDevice.Error.NoMoreInput, final_step);

    const read_without_input = cardiac_no_input_deivce.step();

    try std.testing.expectError(Cardiac.Error.EndOfInput, read_without_input);
}

test "jump" {
    const program =  [_]u64{
        802, // 0: jump to 2
        999, // 1: halt
        801, // 2: jump to 1
    };

    var cardiac = Cardiac.new(null);
    try cardiac.flash(&program);
    try cardiac.step(); // jmp
    try cardiac.step(); // jmp not halt
    const final_step = cardiac.step(); // halt

    try std.testing.expectError(Cardiac.Error.Halted, final_step);
}

test "subtract 7 from 32 expect 25" {
    const program =  [_]u64{
        104, // 0: load  from 4
        705, // 1: sub   from 5
        606, // 2: store to   6
        999, // 3: halt
         32, // 4: data
          7, // 5: data
    };

    var cardiac = Cardiac.new(null);

    try cardiac.flash(&program);

    try cardiac.step(); //load
    try cardiac.step(); //sub
    try cardiac.step(); //store
    const final_step = cardiac.step(); //halt

    try std.testing.expectError(Cardiac.Error.Halted, final_step);
    try std.testing.expectEqual(cardiac.memory[6], 25);
}

test "add 7 to 12 expect 19" {
    const program =  [_]u64{
        104, // 0: load  from 4
        205, // 1: add   from 5
        606, // 2: store to   6
        999, // 3: halt
         12, // 4: data
          7, // 5: data
    };

    var cardiac = Cardiac.new(null);

    try cardiac.flash(&program);

    try cardiac.step(); //load
    try cardiac.step(); //add
    try cardiac.step(); //store
    const final_step = cardiac.step(); //halt

    try std.testing.expectError(Cardiac.Error.Halted, final_step);
    try std.testing.expectEqual(cardiac.memory[6], 19);
}
