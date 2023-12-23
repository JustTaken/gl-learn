const std = @import("std");

pub const Vec = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn init(x: f32, y: f32, z: f32) Vec {
        return .{
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub fn sum(self: Vec, other: Vec) Vec {
        return .{
            .x = other.x + self.x,
            .y = other.y + self.y,
            .z = other.z + self.z,
        };
    }

    pub fn sub(self: Vec, other: Vec) Vec {
        return .{
            .x = other.x - self.x,
            .y = other.y - self.y,
            .z = other.z - self.z,
        };
    }

    pub fn mult(self: Vec, matrix: Matrix) Vec {
        return .{
            .x = self.x * matrix.x[0] + self.y * matrix.x[1] + self.z * matrix.x[2],
            .y = self.x * matrix.y[0] + self.y * matrix.y[1] + self.z * matrix.y[2],
            .z = self.x * matrix.z[0] + self.y * matrix.z[1] + self.z * matrix.z[2],
        };
    }

    pub fn dot(self: Vec, other: Vec) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn angle(self: Vec, other: Vec) f32 {
        const value: f32 = self.normalize().dot(other.normalize());
        return std.math.acos(value);
    }

    pub fn cross(self: Vec, other: Vec) Vec {
        return .{
            .x = self.y * other.z - self.z * other.y,
            .y = self.z * other.x - self.x * other.z,
            .z = self.x * other.y - self.y * other.x,
        };
    }

    pub fn len(self: Vec) f32 {
        return std.math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    pub fn normalize(self: Vec) Vec {
        const length: f32 = self.len();
        return .{
            .x = self.x / length,
            .y = self.y / length,
            .z = self.z / length,
        };
    }
};

pub const Matrix = struct {
    x: [3]f32,
    y: [3]f32,
    z: [3]f32,

    pub fn scale(x: f32, y: f32, z: f32) Matrix {
        return .{
            .x = [3]f32 {x, 0.0, 0.0},
            .y = [3]f32 {0.0, y, 0.0},
            .z = [3]f32 {0.0, 0.0, z},
        };
    }
};

test "dot product" {
    const v1 = Vec.init(1.0, 0.0, 0.0);
    const v2 = Vec.init(0.0, 1.0, 1.0);

    try std.testing.expect(v1.dot(v2) == 0.0);
    try std.testing.expect(Vec.dot(v1, v2) == 0.0);
}
