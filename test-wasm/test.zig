const std = @import("std");

export fn version() i32 {
    return 1;
}

export fn testAdd(a: i32, b: i32) i32 {
    return a + b;
}

export fn testOut(in: i32, result: *i32) void {
    result.* = in * 2;
}

export fn testOut2(a: i32, b: i32, add: *i32, sub: *i32) void {
    add.* = a + b;
    sub.* = a - b;
}

export fn testStringIsHelloWorld(buffer: [*]const u8, length: usize) bool {
    const string = buffer[0..length];
    return std.mem.eql(u8, string, "HelloWorld");
}

export fn testAlloc(key: i32) i32 {
    const allocator = std.heap.page_allocator;

    var map = std.AutoHashMap(i32, i32).init(allocator);
    defer map.deinit();

    map.put(1, 111) catch {};
    map.put(2, 222) catch {};

    return if (map.get(key)) |value| value else -1;
}
