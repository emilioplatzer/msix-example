const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
const uri = std.Uri.parse("https://nodejs.org/dist/index.json") catch unreachable;

const BUFF_SIZE = 256;

// pub fn readAndMakeOneBuff(Request)

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    try stdout.print("Connectiong", .{});
    var req = try client.request(.GET, uri, .{ .allocator = allocator }, .{});
    defer req.deinit();
    try req.start(.{});
    try req.wait();
    try std.testing.expect(req.response.status == .ok);
    try stdout.print("Response: {d}!\n", .{req.response.status});
    try stdout.print("Size: {?d}!\n", .{req.response.content_length});

    const max = 0x1000000;

    const buf: []u8 = try req.reader().readAllAlloc(allocator, max);
    defer allocator.free(buf);
    try stdout.print("Content: {s}\n", .{buf});
}

//
//
