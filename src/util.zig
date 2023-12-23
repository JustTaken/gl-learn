const std = @import("std");

pub fn read_file(path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    const end_pos = try file.getEndPos();
    defer file.close();
    return try file.readToEndAlloc(allocator, end_pos);
    // return try file.readToEndAlloc(allocator, end_pos);
}
