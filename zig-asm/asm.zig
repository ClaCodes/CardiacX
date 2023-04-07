const std = @import("std");

const Allocator = std.mem.Allocator;

const CompileError = error{
    TooManyTokens,
    InvalidOpcode,
    InvalidLabel,
};

fn fileSize(fileName: []const u8) !usize {
    const file = try std.fs.cwd().openFile(fileName, .{});
    return try file.getEndPos();
}

fn fileReadAlloc(fileName: []const u8, allocator: Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    const size = try fileSize(fileName);
    const buffer = try file.readToEndAlloc(allocator, size);
    return buffer;
}

fn isWhiteSpace(char: u8) bool {
    return (char == ' ') or (char == '\t') or (char == '\r') or (char == '\n');
}

fn stringTrim(string: []const u8) []const u8 {
    var start: usize = 0;
    while (start < string.len) {
        if (!isWhiteSpace(string[start])) {
            break;
        }
        start += 1;
    }
    var end: usize = string.len;
    while (end > start) {
        if (!isWhiteSpace(string[end - 1])) {
            break;
        }
        end -= 1;
    }
    return string[start..end];
}

fn stringUncomment(string: []const u8) []const u8 {
    if (std.mem.indexOf(u8, string, "//")) |index| {
        return string[0..index];
    }
    return string[0..];
}

fn isLabel(string: []const u8) bool {
    return string[string.len - 1] == ':';
}

fn isNumber(string: []const u8) bool {
    return (string[0] == '-') or ((string[0] >= '0') and (string[0] <= '9'));
}

const Tokens = struct {
    labelNullable: ?[]const u8,
    opcodeNullable: ?[]const u8,
    paramNullable: ?[]const u8,
};

fn parseLine(line: []const u8) !Tokens {
    var result = Tokens{ .labelNullable = null, .opcodeNullable = null, .paramNullable = null };

    if (line.len == 0) {
        return result; // skip empty lines
    }

    var tokens = std.mem.split(u8, line, " ");
    var nonLabelCount: usize = 0;

    while (tokens.next()) |tokenRaw| {
        const token = stringTrim(tokenRaw);
        if (token.len == 0) {
            continue;
        } else if (isLabel(token)) {
            result.labelNullable = token[0 .. token.len - 1]; // remove colon at the end
        } else if (nonLabelCount == 0) {
            result.opcodeNullable = token;
            nonLabelCount += 1;
        } else if (nonLabelCount == 1) {
            result.paramNullable = token;
            nonLabelCount += 1;
        } else {
            return CompileError.TooManyTokens;
        }
    }

    return result;
}

pub fn assemble(startAddress: usize, endAddress: *usize, memory: *[100]i16, in: []const u8, allocator: Allocator) !void {
    var opcodes = std.StringHashMap(i16).init(allocator);
    try opcodes.put("INP", 0);
    try opcodes.put("CLA", 100);
    try opcodes.put("ADD", 200);
    try opcodes.put("TAC", 300);
    try opcodes.put("SFT", 400);
    try opcodes.put("OUT", 500);
    try opcodes.put("STO", 600);
    try opcodes.put("SUB", 700);
    try opcodes.put("JMP", 800);
    try opcodes.put("HRS", 900);
    defer opcodes.deinit();

    var labels = std.StringHashMap(usize).init(allocator);
    defer labels.deinit();

    var pass: i32 = -1;
    while (pass < 1) {
        var address: usize = startAddress;

        pass += 1;
        var lines = std.mem.split(u8, in, "\n");
        while (lines.next()) |lineRaw| {
            const line: []const u8 = stringUncomment(lineRaw);

            const tokens = try parseLine(line);

            if (tokens.labelNullable) |label| {
                try labels.put(label, address);
            }

            if (pass == 0) {
                address += 1;
                continue;
            }

            if ((tokens.opcodeNullable == null) and (tokens.paramNullable == null)) {
                continue;
            }

            var code: i16 = 1000;

            if (tokens.opcodeNullable) |opcode| {
                if (isNumber(opcode)) {
                    code = try std.fmt.parseInt(i16, opcode, 10);
                } else {
                    if (opcodes.get(opcode)) |value| {
                        code = value;
                    } else {
                        return CompileError.InvalidOpcode;
                    }
                }
            }

            if (tokens.paramNullable) |param| {
                if (isNumber(param)) {
                    code += try std.fmt.parseInt(i16, param, 10);
                } else {
                    if (labels.get(param)) |value| {
                        code += @intCast(i16, value);
                    } else {
                        return CompileError.InvalidLabel;
                    }
                }
            }

            memory[address] = code;
            address += 1;
        }

        endAddress.* = address;
    }
}

pub fn main() !void {
    const stdout = std.io.getStdOut();

    // TODO does not detect leaks during normal runtime or tests?
    //var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //const allocator = gpa.allocator();
    const allocator = std.heap.page_allocator;

    const in = try fileReadAlloc("zig-asm/test.asm", allocator);
    defer allocator.free(in);

    var memory: [100]i16 = undefined;
    var endAddress: usize = 0;

    try assemble(0, &endAddress, &memory, in, allocator);

    for (0..endAddress) |address| {
        try stdout.writer().print("{}\n", .{memory[address]});
    }
}

const test_allocator = std.testing.allocator;

test "assemble file" {
    const in = try fileReadAlloc("zig-asm/test.asm", test_allocator);
    defer test_allocator.free(in);
    var memory: [100]i16 = undefined;
    var endAddress: usize = 0;

    try assemble(0, &endAddress, &memory, in, test_allocator);
}

test "assemble label forward" {
    const in =
        \\ CLA const_3
        \\ const_3: 3
    ;

    var memory: [100]i16 = undefined;
    var endAddress: usize = 0;
    try assemble(0, &endAddress, &memory, in, test_allocator);

    try std.testing.expectEqual(endAddress, 2);
    try std.testing.expectEqual(memory[0], 101);
    try std.testing.expectEqual(memory[1], 3);
}

test "assemble label forward newline" {
    const in =
        \\ CLA const_3
        \\ const_3:
        \\ 3
    ;

    var memory: [100]i16 = undefined;
    var endAddress: usize = 0;
    try assemble(0, &endAddress, &memory, in, test_allocator);

    try std.testing.expectEqual(endAddress, 2);
    try std.testing.expectEqual(memory[0], 101);
    try std.testing.expectEqual(memory[1], 3);
}

test "assemble data" {
    const in =
        \\ 123
        \\ 234
        \\ 456
    ;

    var memory: [100]i16 = undefined;
    var endAddress: usize = 0;
    try assemble(0, &endAddress, &memory, in, test_allocator);

    try std.testing.expectEqual(endAddress, 3);
    try std.testing.expectEqual(memory[0], 123);
    try std.testing.expectEqual(memory[1], 234);
    try std.testing.expectEqual(memory[2], 456);
}

test "assemble comments and whitespace" {
    const in =
        \\
        \\ CLA   01
        \\  CLA 02 // comment
        \\   // comment
        \\
        \\ // comment
    ;

    var memory: [100]i16 = undefined;
    var endAddress: usize = 0;
    try assemble(0, &endAddress, &memory, in, test_allocator);

    try std.testing.expectEqual(endAddress, 2);
    try std.testing.expectEqual(memory[0], 101);
    try std.testing.expectEqual(memory[1], 102);
}

test "assemble all opcodes" {
    const in =
        \\ INP 00
        \\ CLA 00
        \\ ADD 00
        \\ TAC 00
        \\ SFT 00
        \\ OUT 00
        \\ STO 00
        \\ SUB 00
        \\ JMP 00
        \\ HRS 00
    ;

    var memory: [100]i16 = undefined;
    var endAddress: usize = 0;
    try assemble(0, &endAddress, &memory, in, test_allocator);

    try std.testing.expectEqual(endAddress, 10);
    for (0..10) |address| {
        try std.testing.expectEqual(memory[address], @intCast(i16, address * 100));
    }
}

test "assemble empty single line" {
    const in =
        \\
    ;

    var memory: [100]i16 = undefined;
    var endAddress: usize = 0;
    try assemble(0, &endAddress, &memory, in, test_allocator);

    try std.testing.expectEqual(endAddress, 0);
}

test "assemble empty buffer" {
    const in = "";

    var memory: [100]i16 = undefined;
    var endAddress: usize = 0;
    try assemble(0, &endAddress, &memory, in, test_allocator);

    try std.testing.expectEqual(endAddress, 0);
}
