const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("assets/input.txt", .{});

    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();
    var buf: [512]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var map = std.ArrayList([2]usize).init(allocator);

    defer {
        file.close();
        map.deinit();
        const status = gpa.deinit();
        if (status == .leak) {
            @panic("Could not de-initilize the memory\n");
        }
    }

    var line_num: usize = 0;
    var col: usize = 0;
    var empty_lines = [_]bool {true, true, true, true, true, true, true, true, true, true, true, true, };
    var empty_cols = [_]bool {true, true, true, true, true, true, true, true, true, true, true, true, true, };

    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        for (line) |c| {
            if ('#' == c) {
                try map.append(.{line_num, col});
                empty_lines[line_num] = false;
                empty_cols[col] = false;
            }
            col += 1;
        }

        col = 0;
        line_num += 1;
    }

    std.debug.print("{any}", .{empty_lines});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit();
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
