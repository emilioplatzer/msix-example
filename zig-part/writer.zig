const std = @import("std");

var out = std.io.getStdOut().writer();

pub fn main() anyerror!void {
    try out.print("{any}\n", .{@TypeOf(out)});
}
