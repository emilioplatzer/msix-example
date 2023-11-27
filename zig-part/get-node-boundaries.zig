const std = @import("std");
const fs = std.fs;
const os = std.os;
const mem = std.mem;
const ChildProcess = std.ChildProcess;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
const uri = std.Uri.parse("https://nodejs.org/dist/index.json") catch unreachable;

const AWriter = std.fs.File.Writer; // @typeInfo(@TypeOf(std.io.getStdOut().writer)).Fn.return_type.?;

// var stdout: std.fs.File.Writer = null;
// var stdout: AWriter? = null;

fn log() AWriter {
    // if (innerStdout == null) {
    //     innerStdout = std.io.getStdOut().writer();
    // }
    // return innerStdout;
    return std.io.getStdOut().writer();
    // if (!stdout) stdout = std.io.getStdOut().writer();
    // return stdout;
}

const BUFF_SIZE = 256;

const NOT_FOUND: []const u8 = "NOT FOUND";

const NodeVersion = struct {
    version: []const u8,
    date: []const u8,
    // npm: ?[]const u8,
    lts: std.json.Value,
};

const InstallerError = error{
    NodeVersionParseError,
};

fn nodeVersionInPaht() ![]const u8 {
    const result = ChildProcess.exec(.{
        .allocator = allocator,
        .argv = &.{
            "node",
            "--version",
        },
        .env_map = null,
        .max_output_bytes = 100 * 1024 * 1024,
    }) catch |e| switch (e) {
        error.FileNotFound => return NOT_FOUND,
        else => unreachable,
    };
    defer {
        allocator.free(result.stderr);
    }
    try log().print("Instaled node: {s}\n", .{result.stdout});
    return result.stdout;
}

fn getBestNodeVersion() ![]const u8 {
    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    try log().print("Connectiong", .{});
    var req = try client.request(.GET, uri, .{ .allocator = allocator }, .{});
    defer req.deinit();
    try req.start(.{});
    try req.wait();
    try std.testing.expect(req.response.status == .ok);
    try log().print("Response: {d}!\n", .{req.response.status});

    const max = 0x1000000;
    const buf: []const u8 = try req.reader().readAllAlloc(allocator, max);
    defer allocator.free(buf);
    // try log().print("JSON: {s}", .{buf});
    const parsed = try std.json.parseFromSlice([]NodeVersion, allocator, buf, .{ .ignore_unknown_fields = true });
    defer parsed.deinit();
    var nodes = parsed.value;
    var i: u16 = 0;
    while ((i < nodes.len) and mem.eql(u8, switch (nodes[i].lts) {
        std.json.Value.string => |str| str,
        std.json.Value.bool => |b| switch (b) {
            true => "true",
            false => "false",
        },
        else => "ERROR",
    }, "false")) i += 1;
    if (i >= nodes.len) return InstallerError.NodeVersionParseError;
    return allocator.dupe(u8, nodes[i].version);
}

fn installNode() !void {
    var nodeVersion = try getBestNodeVersion();
    defer allocator.free(nodeVersion);
    try log().print("Preparando la instalación de Node: {s}\n", .{nodeVersion});
}

pub fn main() !void {
    // stdout = std.io.getStdOut().writer();
    var nodeVersion = try nodeVersionInPaht();
    if (mem.eql(u8, nodeVersion, NOT_FOUND)) {
        try installNode();
    }
    try log().print("nodeVersion: {s}\n", .{nodeVersion});

    // try stdout.print("Content: {s}\n", .{buf});
}

// c:\bin\zig\zig build-exe get-node-boundaries.zig && get-node-boundaries.exe
//
