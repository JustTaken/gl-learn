const std = @import("std");
const Vec = @import("math.zig").Vec;
const Matrix = @import("math.zig").Matrix;

pub const Camera = struct {
    up: Vec,
    eye: Vec,
    center: Vec,

    pub fn default() Camera {
        return .{
            .eye = Vec.init(0.0, 0.0, 1.0),
            .center = Vec.init(0.0, 0.0, 0.0),
            .up = Vec.init(0.0, 1.0, 0.0),
        };
    }

    pub fn init(eye: Vec, center: Vec, up: Vec) Camera {
        return .{
            .eye = eye,
            .center = center,
            .up = up,
        };
    }

    pub fn view_matrix(self: Camera) [4][4]f32 {
        const direction = Vec.sub(self.center, self.eye);
        const right = Vec.cross(direction, self.up).normalize();

        return Matrix.mult([4][4]f32 {
            [4]f32 {right.x, self.up.x, direction.x, 0.0},
            [4]f32 {right.y, self.up.y, direction.y, 0.0},
            [4]f32 {right.z, self.up.z, direction.z, 0.0},
            [4]f32 {0.0, 0.0, 0.0, 1.0},
        }, [4][4]f32 {
            [4]f32 {1.0, 0.0, 0.0, 0.0},
            [4]f32 {0.0, 1.0, 0.0, 0.0},
            [4]f32 {0.0, 0.0, 1.0, 0.0},
            [4]f32 {-self.eye.x, -self.eye.y, -self.eye.z, 1.0},
        });
    }

    pub fn foward(self: *Camera) void {
        self.eye = Vec.sub(self.eye.normalize().mult(0.01), self.eye);
    }

    pub fn backward(self: *Camera) void {
        self.eye = Vec.sum(self.eye.normalize().mult(0.01), self.eye);
    }
};

pub fn read_file(path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const end_pos = try file.getEndPos();
    return try file.readToEndAlloc(allocator, end_pos);
}
