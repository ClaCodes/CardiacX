const std = @import("std");

pub const BusDevice = union(enum) {
    storage: StorageDevice,
    io: IODevice,

    pub fn read(self: *@This()) !u64 {
        switch (self.*) {
            .storage => return self.storage.read(),
            .io => return self.io.read(),
        }
    }

    pub fn write(self: *@This(), out: u64) !void {
        switch (self.*) {
            .storage => try self.storage.write(out),
            .io => try self.io.write(out),
        }
    }

    pub const Error = error {
        WriteError,
        NoMoreInput
    };
};

pub const StorageDevice = struct {
    read_counter: usize,
    read_buffer: []const u64,
    write_counter: usize,
    write_buffer: []u64,

    pub fn new(read_buffer: []const u64, write_buffer: []u64) StorageDevice {
        return StorageDevice {
            .read_counter = 0,
            .read_buffer = read_buffer,
            .write_counter = 0,
            .write_buffer = write_buffer,
        };
    }

    fn read(self: *@This()) !u64 {
        self.read_counter += 1;
        if (self.read_counter <= self.read_buffer.len) {
            return self.read_buffer[self.read_counter - 1];
        }
        return BusDevice.Error.NoMoreInput;
    }

    fn write(self: *@This(), out: u64) !void {
        self.write_counter += 1;
        if (self.write_counter <= self.write_buffer.len) {
            self.write_buffer[self.write_counter - 1] = out;
        } else {
            return BusDevice.Error.WriteError;
        }
    }
};

const stdin_file = std.io.getStdIn().reader();
var br = std.io.bufferedReader(stdin_file);
const stdin = br.reader();

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

pub const IODevice = struct {

    pub fn new() IODevice {
        return IODevice { };
    }

    fn read(self: *@This()) !u64 {
        _ = self;
        var str: [9]u8 = undefined;
        const have_read = try stdin.readUntilDelimiterOrEof(&str, '\n');
        if (have_read) |string| {
            return std.fmt.parseInt(u64, string, 10);
        }
        return BusDevice.Error.NoMoreInput;
    }

    fn write(self: *@This(), out: u64) !void {
        _ = self;
        try stdout.print("{}\n", .{out});
        try bw.flush();
    }
};


