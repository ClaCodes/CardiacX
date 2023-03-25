const std = @import("std");
const Cardiac = @import("cardiac.zig").Cardiac;
const BusDevice = @import("bus.zig").BusDevice;
const IODevice = @import("bus.zig").IODevice;

pub fn main() !void {
    // program that reads from std input,
    // doubles the number and outputs it to stdout
    const program =  [_]u64{
          6, // 0: input  to 6
        106, // 1: load from 6
        206, // 2: add  from 6
        606, // 3: store  to 6
        506, // 4: out  from 6
        800, // 5: jmp    to 0
    };

    var io: BusDevice = .{.io = IODevice.new()};

    var cardiac = Cardiac.new(&io);
    try cardiac.flash(&program);

    cardiac.run();
}

