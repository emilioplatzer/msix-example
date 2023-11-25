const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, {s}!\n", .{"world"});
}

// const print = @import("std").debug.print;
// 
// pub fn main() void {
//     print("Hello, {s} 2!\n", .{"world"});
// }

// c:\bin\zig\zig build-exe hello.zig