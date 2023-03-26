const std = @import("std");

const Allocator = std.mem.Allocator;

const CompileError = error{
    TooManyTokens,
};

pub fn fileReadAlloc(fileName: []const u8, allocator: Allocator) ![]u8 {
    var file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    const buffer = try file.readToEndAlloc(allocator, 4096);
    return buffer;
}

pub fn stringUpperAlloc(string: []const u8, allocator: Allocator) ![]u8 {
    const result = try allocator.alloc(u8, string.len);
    for (string, 0..) |char, i| {
        result[i] = std.ascii.toUpper(char);
    }
    return result;
}

pub fn isSpaceOrTab(char: u8) bool {
    return (char == ' ') or (char == '\t');
}

pub fn stringTrim(string: []const u8) []const u8 {
    var start: usize = 0;
    while (start < string.len) {
        if (!isSpaceOrTab(string[start])) {
            break;
        }
        start += 1;
    }
    var end: usize = string.len;
    while (end > start) {
        if (!isSpaceOrTab(string[end - 1])) {
            break;
        }
        end -= 1;
    }
    return string[start..end];
}

pub fn stringUncomment(string: []const u8) []const u8 {
    if (std.mem.indexOf(u8, string, "//")) |index| {
        return string[0..index];
    }
    return string[0..];
}

pub fn isLabel(string: []const u8) bool {
    return string[string.len - 1] == ':';
}

pub fn isNumber(string: []const u8) bool {
    return (string[0] == '-') or ((string[0] >= '0') and (string[0] <= '9'));
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const allocator = std.heap.page_allocator;

    var address: usize = 0;

    // switch does not work on strings, big if/else?
    var opcodes = std.StringHashMap(usize).init(allocator);
    try opcodes.put("INP", 0);
    try opcodes.put("CLA", 1);
    try opcodes.put("ADD", 2);
    try opcodes.put("TAC", 3);
    try opcodes.put("SFT", 4);
    try opcodes.put("OUT", 5);
    try opcodes.put("STO", 6);
    try opcodes.put("SUB", 7);
    try opcodes.put("JMP", 8);
    try opcodes.put("HRS", 9);

    var labels = std.StringHashMap(usize).init(allocator);
    defer labels.deinit();

    var all = try fileReadAlloc("test.asm", allocator);
    defer allocator.free(all);

    for (0..2) |pass| {
        var lines = std.mem.split(u8, all, "\n");
        while (lines.next()) |lineRaw| {
            // TODO not possible create a dynamic one on the stack :(
            const lineUpper: []u8 = stringUpperAlloc(lineRaw, allocator) catch "";
            // TODO defer allocator.free(lineUpper); crashes, maybe because part of it maybe in the map?
            // TODO remove this idea about uppercasing alltogheter, just left here as an excercise for the moment

            const line: []const u8 = stringTrim(stringUncomment(lineUpper));
            if (line.len == 0) {
                continue;
            }

            var opcodeNullable: ?[]const u8 = null;
            var paramNullable: ?[]const u8 = null;
            var tokens = std.mem.split(u8, line, " ");
            var nonLabelCount: usize = 0;

            while (tokens.next()) |tokenRaw| {
                const token = stringTrim(tokenRaw);
                if (token.len == 0) {
                    continue;
                }
                if (isLabel(token)) {
                    const label = token[0 .. token.len - 1];
                    if(pass == 0) {
                        try labels.put(label, address);
                    }
                } else if (nonLabelCount == 0) {
                    opcodeNullable = token;
                    nonLabelCount += 1;
                } else if (nonLabelCount == 1) {
                    paramNullable = token;
                    nonLabelCount += 1;
                } else {
                    return CompileError.TooManyTokens;
                }
            }

            if ((opcodeNullable == null) and (paramNullable == null)) {
                continue;
            }

            var code: i16 = 1000;

            address += 1;

            if(pass == 0) {
                continue;
            }

            if (opcodeNullable) |opcode| {
                if (isNumber(opcode)) {
                    code = try std.fmt.parseInt(i16, opcode, 10);
                } else {
                    if (opcodes.get(opcode)) |value| {
                        code = @intCast(i16, value) * 100;
                    }
                }
            }

            if (paramNullable) |param| {
                if (isNumber(param)) {
                    code += try std.fmt.parseInt(i16, param, 10);
                } else {
                    if (labels.get(param)) |value| {
                        code += @intCast(i16, value);
                    }
                }
            }

            try stdout.print("{}\n", .{code});
        }
    }
}
