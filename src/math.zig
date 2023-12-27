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

    // pub fn mult(self: Vec, matrix: Matrix) Vec {
    //     return .{
    //         .x = self.x * matrix.x[0] + self.y * matrix.x[1] + self.z * matrix.x[2],
    //         .y = self.x * matrix.y[0] + self.y * matrix.y[1] + self.z * matrix.y[2],
    //         .z = self.x * matrix.z[0] + self.y * matrix.z[1] + self.z * matrix.z[2],
    //     };
    // }

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
    pub fn scale(x: f32, y: f32, z: f32) [4][4]f32 {
        return .{
            [4]f32 {x, 0.0, 0.0, 0.0},
            [4]f32 {0.0, y, 0.0, 0.0},
            [4]f32 {0.0, 0.0, z, 0.0},
            [4]f32 {0.0, 0.0, 0.0, 1.0}
        };
    }

    pub fn xrotation(theta: f32) [4][4]f32 {
        return .{
            [4]f32 {1.0, 0.0, 0.0, 0.0},
            [4]f32 {0.0, std.math.cos(theta), -std.math.sin(theta), 0.0},
            [4]f32 {0.0, std.math.sin(theta), std.math.cos(theta), 0.0},
            [4]f32 {0.0, 0.0, 0.0, 1.0},
        };
    }

    pub fn yrotation(theta: f32) [4][4]f32 {
        return .{
            [4]f32 {std.math.cos(theta), 0.0, std.math.sin(theta), 0.0},
            [4]f32 {0.0, 1.0, 0.0, 0.0},
            [4]f32 {-std.math.sin(theta), 0.0, std.math.cos(theta), 0.0},
            [4]f32 {0.0, 0.0, 0.0, 1.0},
        };
    }

    pub fn zrotation(theta: f32) [4][4]f32 {
        return .{
            [4]f32 {std.math.cos(theta), -std.math.sin(theta), 0.0, 0.0},
            [4]f32 {std.math.sin(theta), std.math.cos(theta), 0.0, 0.0},
            [4]f32 {0.0, 0.0, 1.0, 0.0},
            [4]f32 {0.0, 0.0, 0.0, 1.0},
        };
    }

    pub fn translate(x: f32, y: f32, z: f32) [4][4]f32 {
        return .{
            [4]f32 {1.0, 0.0, 0.0, 0.0},
            [4]f32 {0.0, 1.0, 0.0, 0.0},
            [4]f32 {0.0, 0.0, 1.0, 0.0},
            [4]f32 {x, y, z, 1.0},
        };
    }

    pub fn perspective(fovy: f32, aspect: f32, near: f32, far: f32) [4][4]f32 {
        const top: f32 = std.math.tan(fovy * 0.5) * near;
        const bottom = -top;
        const right = top * aspect;
        const left = -right;

        return [4][4]f32 {
            [4]f32 {2 * near / (right - left), 0.0, 0.0, 0.0},
            [4]f32 {0.0, 2 * near / (top - bottom), 0.0, 0.0},
            [4]f32 {(right + left) / (right - left), (top + bottom) / (top - bottom), -(far + near) / (far - near), -1.0},
            [4]f32 {0.0, 0.0, -2 * far * near / (far - near), 0.0},
        };
    }

    pub fn mult(m1: [4][4]f32, m2: [4][4]f32) [4][4]f32 {
        return .{
            [4]f32 {m2[0][0] * m1[0][0] + m2[0][1] * m1[1][0] + m2[0][2] * m1[2][0] + m2[0][3] * m1[3][0], m2[0][0] * m1[0][1] + m2[0][1] * m1[1][1] + m2[0][2] * m1[2][1] + m2[0][3] * m1[3][1], m2[0][0] * m1[0][2] + m2[0][1] * m1[1][2] + m2[0][2] * m1[2][2] + m2[0][3] * m1[3][2], m2[0][0] * m1[0][3] + m2[0][1] * m1[1][3] + m2[0][2] * m1[2][3] + m2[0][3] * m1[3][3]},
            [4]f32 {m2[1][0] * m1[0][0] + m2[1][1] * m1[1][0] + m2[1][2] * m1[2][0] + m2[1][3] * m1[3][0], m2[1][0] * m1[0][1] + m2[1][1] * m1[1][1] + m2[1][2] * m1[2][1] + m2[1][3] * m1[3][1], m2[1][0] * m1[0][2] + m2[1][1] * m1[1][2] + m2[1][2] * m1[2][2] + m2[1][3] * m1[3][2], m2[1][0] * m1[0][3] + m2[1][1] * m1[1][3] + m2[1][2] * m1[2][3] + m2[1][3] * m1[3][3]},
            [4]f32 {m2[2][0] * m1[0][0] + m2[2][1] * m1[1][0] + m2[2][2] * m1[2][0] + m2[2][3] * m1[3][0], m2[2][0] * m1[0][1] + m2[2][1] * m1[1][1] + m2[2][2] * m1[2][1] + m2[2][3] * m1[3][1], m2[2][0] * m1[0][2] + m2[2][1] * m1[1][2] + m2[2][2] * m1[2][2] + m2[2][3] * m1[3][2], m2[2][0] * m1[0][3] + m2[2][1] * m1[1][3] + m2[2][2] * m1[2][3] + m2[2][3] * m1[3][3]},
            [4]f32 {m2[3][0] * m1[0][0] + m2[3][1] * m1[1][0] + m2[3][2] * m1[2][0] + m2[3][3] * m1[3][0], m2[3][0] * m1[0][1] + m2[3][1] * m1[1][1] + m2[3][2] * m1[2][1] + m2[3][3] * m1[3][1], m2[3][0] * m1[0][2] + m2[3][1] * m1[1][2] + m2[3][2] * m1[2][2] + m2[3][3] * m1[3][2], m2[3][0] * m1[0][3] + m2[3][1] * m1[1][3] + m2[3][2] * m1[2][3] + m2[3][3] * m1[3][3]},
        };
    }
};
