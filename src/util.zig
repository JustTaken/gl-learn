const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("glad/glad.h");
});

const ArrayList = std.ArrayList;
const Vec = @import("math.zig").Vec;
const Matrix = @import("math.zig").Matrix;

pub const OpenGL = struct {
    window: *c.SDL_Window,
    context: c.SDL_GLContext,
    array_obj: [2]u32,
    shader_program: u32,
    camera: Camera,
    cubes: ArrayList(Cube),
    running: bool,
};

pub const Cube = struct {
    position: Vec,
    color: [4][4]f32 ,

    pub const number_of_points: i32 = 12;

    pub fn model(self: Cube, rotation: [4][4]f32) [4][4]f32 {
        const translation: [4][4]f32 = Matrix.translate(self.position.x, self.position.y, self.position.z);

        return Matrix.mult(translation, rotation);
    }
};

pub const Camera = struct {
    up: Vec,
    eye: Vec,
    center: Vec,

    pub fn default() Camera {
        return .{
            .eye = Vec.init(0.0, 0.0, 2.0),
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
        const right = Vec.cross(self.up, direction).normalize();

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

    pub fn mouse(self: *Camera, x: i32, y: i32) void {
        var direction = Vec.sub(self.eye, self.center);
        const right = Vec.cross(direction, self.up);

        const rotate = Matrix.mult(
            Matrix.rotate(
                @as(f32, @floatFromInt(x)) * std.math.pi * 0.1 / -180.0,
                self.up.normalize()
            ),
            Matrix.rotate(
                @as(f32, @floatFromInt(y)) * std.math.pi * 0.1 / -180.0,
                right.normalize()
            )
        );

        direction = Vec.mult(
            direction,
            rotate
        );

        self.center = Vec.sum(self.eye, direction);
        self.up = Vec.cross(right, direction).normalize();
    }

    pub fn move_foward(self: *Camera, speed: f32) void {
        const direction = Vec.sub(self.eye, self.center);
        self.eye = Vec.sum(direction.normalize().scale(speed * 10.0), self.eye);
    }

    pub fn move_backward(self: *Camera, speed: f32) void {
        const direction = Vec.sub(self.eye, self.center);
        self.eye = Vec.sub(direction.normalize().scale(speed * 10.0), self.eye);
    }

    pub fn move_right(self: *Camera, speed: f32) void {
        const delta = Vec.cross(Vec.sub(self.eye, self.center), self.up).normalize().scale(speed * 10.0);
        self.eye = Vec.sum(delta, self.eye);
        self.center = Vec.sum(delta, self.center);
    }

    pub fn move_left(self: *Camera, speed: f32) void {
        const delta = Vec.cross(Vec.sub(self.eye, self.center), self.up).normalize().scale(speed * 10.0);
        self.eye = Vec.sub(delta, self.eye);
        self.center = Vec.sub(delta, self.center);
    }
};

pub fn read_file(path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    const end_pos = try file.getEndPos();
    defer file.close();

    return try file.readToEndAlloc(allocator, end_pos);
}
