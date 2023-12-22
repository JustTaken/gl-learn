const std = @import("std");

const hash = '#';

pub fn main() !void {
    const file = try std.fs.cwd().openFile("assets/input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();
    var buf: [512]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var map = try allocator.alloc([2]usize, 0);
    defer {
        allocator.free(map);
        const status = gpa.deinit();
        if (status == .leak) {
            @panic("Could not de initilize the memory\n");
        }
    }
    var line_num: usize = 0;
    var col: usize = 0;
    var index: usize = 0;

    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        for (line) |c| {
            if (hash == c) {
                map = try allocator.realloc(map, index + 1);
                map[index] = .{line_num, col};
                index += 1;
            }
            col += 1;
        }
        col = 0;
        line_num += 1;
    }

    std.debug.print("{d}\n", .{map});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit();
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
