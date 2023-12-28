const std = @import("std");
const math = @import("math.zig");
const util = @import("util.zig");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("glad/glad.h");
});

const OpenGL = util.OpenGL;
const Cube = util.Cube;
const Vec = math.Vec;
const Matrix = math.Matrix;

const APPLICATION_NAME = "OpenGL Window";
const SCREEN_WIDTH: isize = 640;
const SCREEN_HEIGHT: isize = 480;
var rotate: f32 = 0.0;
var last_frame: f32 = 0.0;

fn initizlize(allocator: std.mem.Allocator) !OpenGL {
    const window = c.SDL_CreateWindow(APPLICATION_NAME, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, c.SDL_WINDOW_OPENGL) orelse return error.InitializeError;
    const context = c.SDL_GL_CreateContext(window) orelse return error.InitializeError;

    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) return error.InitializeError;
    if (c.gladLoadGLLoader(c.SDL_GL_GetProcAddress) == 0) return error.InitializeErorr;

    var cubes = std.ArrayList(Cube).init(allocator);
    try cubes.appendSlice(&(
        [_]Cube {
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
        })
    );

    return .{
        .window = window,
        .context = context,
        .array_obj = [2]u32 {0, 0},
        .shader_program = 0,
        .camera = util.Camera.default(),
        .cubes = cubes,
        .running = true,
    };
}

fn vertex_specification(gl: *OpenGL) !void {
    var buffer_obj: [2]u32 = [2]u32 {0, 0};
    var index_buffer_obj: [2]u32 = [2]u32 {0, 0};

    const size = @sizeOf(f32);
    const cube_index_buffer = [_]u32 {0, 2, 1, 3, 2, 0, 0, 1, 4, 4, 1, 5, 5, 1, 6, 6, 2, 1, 6, 5, 4, 4, 7, 6, 7, 4, 0, 3, 0, 7, 3, 7, 2, 2, 7, 6};
    const plane_index_buffer = [_]u32 {0, 1, 2, 0, 3, 1};
    const plane_vertex_buffer = [_]f32 {
        -1.0, -1.0, 1.0, 1.0, 1.0, 1.0,
        1.0, -1.0, -1.0, 1.0, 1.0, 1.0,
        1.0, -1.0, 1.0, 1.0, 1.0, 1.0,
        -1.0, -1.0, -1.0, 1.0, 1.0, 1.0,
    };
    const cube_vertex_buffer = [_]f32 { 
        -1.0, -1.0, 1.0, 1.0, 1.0, 1.0,
        -1.0,  1.0, 1.0, 1.0, 1.0, 1.0,
        1.0,  1.0, 1.0, 1.0, 1.0, 1.0,
        1.0, -1.0, 1.0, 1.0, 1.0, 1.0,

        -1.0, -1.0, -1.0, 1.0, 1.0, 1.0,
        -1.0, 1.0, -1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, -1.0, 1.0, 1.0, 1.0,
        1.0, -1.0, -1.0, 1.0, 1.0, 1.0,
    };

    c.glGenVertexArrays(2, &gl.array_obj[0]);
    c.glBindVertexArray(gl.array_obj[0]);

    c.glGenBuffers(2, &buffer_obj[0]);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, buffer_obj[0]);
    c.glBufferData(c.GL_ARRAY_BUFFER, size * cube_vertex_buffer.len, &cube_vertex_buffer, c.GL_STATIC_DRAW);

    c.glGenBuffers(2, &index_buffer_obj[0]);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, index_buffer_obj[0]);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(u32) * cube_index_buffer.len, &cube_index_buffer, c.GL_STATIC_DRAW);

    const position_location: u32 = @bitCast(c.glGetAttribLocation(gl.shader_program, "position"));
    const color_location: u32 = @bitCast(c.glGetAttribLocation(gl.shader_program, "vertex_color"));
    if (position_location < 0 or color_location < 0) return error.AttribLocationNotFound;

    c.glEnableVertexAttribArray(position_location);
    c.glVertexAttribPointer(position_location, 3, c.GL_FLOAT, c.GL_FALSE, size * 6, @ptrFromInt(0));

    c.glEnableVertexAttribArray(color_location);
    c.glVertexAttribPointer(color_location, 3, c.GL_FLOAT, c.GL_FALSE, size * 6, @ptrFromInt(size * 3));

    c.glBindVertexArray(gl.array_obj[1]);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, buffer_obj[1]);
    c.glBufferData(c.GL_ARRAY_BUFFER, size * plane_vertex_buffer.len, &plane_vertex_buffer, c.GL_STATIC_DRAW);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, index_buffer_obj[1]);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(u32) * plane_index_buffer.len, &plane_index_buffer, c.GL_STATIC_DRAW);

    c.glEnableVertexAttribArray(position_location);
    c.glVertexAttribPointer(position_location, 3, c.GL_FLOAT, c.GL_FALSE, size * 6, @ptrFromInt(0));

    c.glEnableVertexAttribArray(color_location);
    c.glVertexAttribPointer(color_location, 3, c.GL_FLOAT, c.GL_FALSE, size * 6, @ptrFromInt(size * 3));

    c.glBindVertexArray(0);
    c.glDisableVertexAttribArray(color_location);
}

fn create_graphics_pipeline(gl: *OpenGL, allocator: std.mem.Allocator) !void {
    var program_obj = c.glCreateProgram();

    const vertex_shader: u32 = c.glCreateShader(c.GL_VERTEX_SHADER);
    const fragment_shader: u32 = c.glCreateShader(c.GL_FRAGMENT_SHADER);

    const f_shader = try util.read_file("assets/frag.glsl", allocator);
    c.glShaderSource(fragment_shader, 1, &&f_shader[0], null);
    
    const v_shader = try util.read_file("assets/vert.glsl", allocator);
    c.glShaderSource(vertex_shader, 1, &&v_shader[0], null);

    defer {
        allocator.free(v_shader);
        allocator.free(f_shader);
    }

    c.glCompileShader(vertex_shader);
    c.glCompileShader(fragment_shader);

    c.glAttachShader(program_obj, fragment_shader);
    c.glAttachShader(program_obj, vertex_shader);

    c.glLinkProgram(program_obj);
    c.glValidateProgram(program_obj);

    gl.shader_program = program_obj;
}

fn input(gl: *OpenGL) void {
    var event: c.SDL_Event = undefined;

    const current_frame: f32 = @as(f32, @floatFromInt(c.SDL_GetTicks()));
    const delta_time: f32 = (current_frame - last_frame) / 1000.0;

    last_frame = current_frame;
    rotate += 1;

    c.SDL_WarpMouseInWindow(gl.window, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2);
    _ = c.SDL_SetRelativeMouseMode(c.SDL_TRUE);

    while (c.SDL_PollEvent(&event) != 0) {
        if (event.type == c.SDL_QUIT) {
            gl.running = false;
            break;
        } else if (event.type == c.SDL_MOUSEMOTION) {
            gl.camera.mouse(event.motion.xrel, event.motion.yrel);
        } else if (event.type == c.SDL_KEYDOWN) {
            const state: [*c]const u8 = c.SDL_GetKeyboardState(null);

            if (state[c.SDL_SCANCODE_W] != 0) gl.camera.move_foward(delta_time);
            if (state[c.SDL_SCANCODE_S] != 0) gl.camera.move_backward(delta_time);
            if (state[c.SDL_SCANCODE_D] != 0) gl.camera.move_right(delta_time);
            if (state[c.SDL_SCANCODE_A] != 0) gl.camera.move_left(delta_time);
        }
    }
}

fn pre_draw(gl: *OpenGL) void {
    c.glEnable(c.GL_DEPTH_TEST);
    c.glDepthFunc(c.GL_LESS);
    c.glDisable(c.GL_CULL_FACE);
    c.glViewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    c.glClearColor(1.0, 1.0, 1.0, 1.0);
    c.glClear(c.GL_DEPTH_BUFFER_BIT | c.GL_COLOR_BUFFER_BIT);
    c.glUseProgram(gl.shader_program);

    const projection: [4][4]f32 = math.Matrix.perspective(30.0 * std.math.pi / 180.0, @as(f32, SCREEN_WIDTH) / @as(f32, SCREEN_HEIGHT), 0.1, 100.0);
    const view = gl.camera.view_matrix();

    const projection_location = c.glGetUniformLocation(gl.shader_program, "u_projection");
    const view_location = c.glGetUniformLocation(gl.shader_program, "u_view");

    c.glUniformMatrix4fv(projection_location, 1, c.GL_FALSE, &projection[0][0]);
    c.glUniformMatrix4fv(view_location, 1, c.GL_FALSE, &view[0][0]);
}

fn draw(gl: *OpenGL) void {
    c.glBindVertexArray(gl.array_obj[0]);

    const color_location = c.glGetUniformLocation(gl.shader_program, "u_color_model");
    const model_location = c.glGetUniformLocation(gl.shader_program, "u_model");
    const rotation = math.Matrix.rotate(rotate * std.math.pi / 180.0, math.Vec.init(0.5, 1.0, 0.0));

    for (gl.cubes.items) |cube| {
        const model = cube.model(rotation);

        c.glUniformMatrix4fv(model_location, 1, c.GL_FALSE, &model[0][0]);
        c.glUniformMatrix4fv(color_location, 1, c.GL_FALSE, &cube.color[0][0]);
        c.glDrawElements(c.GL_TRIANGLES, Cube.number_of_points * 3, c.GL_UNSIGNED_INT, @ptrFromInt(0));
    }

    c.glBindVertexArray(gl.array_obj[1]);
    const model = Matrix.mult(Matrix.translate(0.0, -2.0, -5.0), Matrix.scale(10.0, 0.0, 10.0));
    const color = Matrix.scale(0.0, 0.0, 1.0);
    c.glUniformMatrix4fv(model_location, 1, c.GL_FALSE, &model[0][0]);
    c.glUniformMatrix4fv(color_location, 1, c.GL_FALSE, &color[0][0]);
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, @ptrFromInt(0));
}

fn cleanup(gl: OpenGL) void {
    c.glDeleteVertexArrays(1, &gl.array_obj);
    c.glDeleteProgram(gl.shader_program);
    c.SDL_DestroyWindow(gl.window);
    c.SDL_Quit();
}

fn loop(gl: *OpenGL) !void {
    while (gl.running) {
        input(gl);
        pre_draw(gl);
        draw(gl);
        c.SDL_GL_SwapWindow(gl.window);
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var gl = try initizlize(allocator);
    try create_graphics_pipeline(&gl, allocator);
    try vertex_specification(&gl);
    try loop(&gl);
    cleanup(gl);
}
