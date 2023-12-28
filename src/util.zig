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
    planes: ArrayList(Plane),
    running: bool,
};

pub const Plane = struct {
    position: Vec,
    color: [4][4]f32,

    pub const number_of_triangles: i32 = 2;
    pub const index_buffer = [_]u32 {0, 1, 2, 0, 3, 1};
    pub const vertex_buffer = [_]f32 {
        -1.0, -1.0, 1.0, 1.0, 1.0, 1.0,
        1.0, -1.0, -1.0, 1.0, 1.0, 1.0,
        1.0, -1.0, 1.0, 1.0, 1.0, 1.0,
        -1.0, -1.0, -1.0, 1.0, 1.0, 1.0,
    };

    const scale = Matrix.scale(10.0, 0.0, 10.0);

    pub fn model(self: Plane) [4][4]f32 {
        return Matrix.mult(Matrix.translate(self.position.x, self.position.y, self.position.z), scale);
    }

    pub fn generate_collection(allocator: std.mem.Allocator) !ArrayList(Plane) {
        var planes = std.ArrayList(Plane).init(allocator);
        try planes.append(Plane {
            .position = Vec.init(0.0, -2.0, -5.0),
            .color = Matrix.scale(0.0, 0.0, 1.0),
        });

        return planes;
    }
};

pub const Cube = struct {
    position: Vec,
    color: [4][4]f32 ,

    pub const number_of_triangles: i32 = 12;
    pub const index_buffer = [_]u32 {0, 2, 1, 3, 2, 0, 0, 1, 4, 4, 1, 5, 5, 1, 6, 6, 2, 1, 6, 5, 4, 4, 7, 6, 7, 4, 0, 3, 0, 7, 3, 7, 2, 2, 7, 6};
    pub const vertex_buffer = [_]f32 {
        -1.0, -1.0, 1.0, 1.0, 1.0, 1.0,
        -1.0,  1.0, 1.0, 1.0, 1.0, 1.0,
        1.0,  1.0, 1.0, 1.0, 1.0, 1.0,
        1.0, -1.0, 1.0, 1.0, 1.0, 1.0,

        -1.0, -1.0, -1.0, 1.0, 1.0, 1.0,
        -1.0, 1.0, -1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, -1.0, 1.0, 1.0, 1.0,
        1.0, -1.0, -1.0, 1.0, 1.0, 1.0,
    };

    pub fn model(self: Cube, rotation: [4][4]f32) [4][4]f32 {
        const translation: [4][4]f32 = Matrix.translate(self.position.x, self.position.y, self.position.z);

        return Matrix.mult(translation, rotation);
    }

    pub fn generate_collection(allocator: std.mem.Allocator) !ArrayList(Cube) {
        var cubes = std.ArrayList(Cube).init(allocator);
        try cubes.appendSlice(
            &[_]Cube {
                Cube {
                    .position = Vec.init(0.0, 0.0, 0.0),
                    .color = Matrix.scale(1.0, 0.0, 0.0),
                },
                Cube {
                    .position = Vec.init(2.0, 5.0, -15.0),
                    .color = Matrix.scale(0.0, 1.0, 0.0),
                },
                Cube {
                    .position = Vec.init(3.0, -2.0, -3.0),
                    .color = Matrix.scale(0.0, 0.0, 1.0),
                },
                Cube {
                    .position = Vec.init(-1.5, -2.2, -2.5),
                    .color = Matrix.scale(0.0, 0.5, 1.0),
                },  
                Cube {
                    .position = Vec.init(-3.8, -2.0, -12.3),
                    .color = Matrix.scale(0.4, 0.5, 0.0),
                },  
                Cube {
                    .position = Vec.init( 2.4, -0.4, -3.5),
                    .color = Matrix.scale(1.0, 0.5, 0.0),
                },  
                Cube {
                    .position = Vec.init(-1.7,  3.0, -7.5),
                    .color = Matrix.scale(0.3, 0.9, 0.2),
                },  
                Cube {
                    .position = Vec.init( 1.3, -2.0, -2.5),
                    .color = Matrix.scale(0.4, 0.0, 0.7),
                },  
                Cube {
                    .position = Vec.init( 1.5,  2.0, -2.5),
                    .color = Matrix.scale(0.8, 0.0, 0.0),
                }, 
                Cube {
                    .position = Vec.init( 1.5,  0.2, -1.5),
                    .color = Matrix.scale(0.0, 0.0, 0.3),
                }, 
                Cube {
                    .position = Vec.init(-1.3,  1.0, -1.5),
                    .color = Matrix.scale(0.7, 0.9, 0.9),
                }  
            }
        );

        return cubes;
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
        const delta = Vec.sub(self.eye, self.center).normalize().scale(speed * 10.0);
        self.eye = Vec.sum(delta, self.eye);
        self.center = Vec.sum(delta, self.center);
    }

    pub fn move_backward(self: *Camera, speed: f32) void {
        const delta = Vec.sub(self.eye, self.center).normalize().scale(speed * 10.0);
        self.eye = Vec.sub(delta, self.eye);
        self.center = Vec.sum(delta, self.center);
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

    pub fn move_up(self: *Camera, speed: f32) void {
        self.eye = Vec.sum(self.up.normalize().scale(speed * 10.0), self.eye);
    }

    pub fn move_down(self: *Camera, speed: f32) void {
        self.eye = Vec.sub(self.up.normalize().scale(speed * 10.0), self.eye);
    }
};

pub const Io = struct {
    pub fn read_file(path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        var file = try std.fs.cwd().openFile(path, .{});
        const end_pos = try file.getEndPos();
        defer file.close();

        return try file.readToEndAlloc(allocator, end_pos);
    }
};
