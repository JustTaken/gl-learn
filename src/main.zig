const std = @import("std");
const math = @import("math.zig");
const util = @import("util.zig");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("glad/glad.h");
});

const Allocator = std.mem.Allocator;

const OpenGL = util.OpenGL;
const Cube = util.Cube;
const Plane = util.Plane;
const Io = util.Io;

const Vec = math.Vec;
const Matrix = math.Matrix;

const APPLICATION_NAME: [*c]const u8 = "OpenGL Window";
const SCREEN_WIDTH: isize = 640;
const SCREEN_HEIGHT: isize = 480;

fn initizlize(allocator: Allocator) !OpenGL {
    const window = c.SDL_CreateWindow(APPLICATION_NAME, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, c.SDL_WINDOW_OPENGL) orelse return error.InitializeError;
    const context = c.SDL_GL_CreateContext(window) orelse return error.InitializeError;

    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) return error.InitializeError;
    if (c.gladLoadGLLoader(c.SDL_GL_GetProcAddress) == 0) return error.InitializeErorr;

    return .{
        .window = window,
        .context = context,
        .array_obj = [2]u32 {0, 0},
        .shader_program = 0,
        .camera = util.Camera.default(),
        .cubes = try Cube.generate_collection(allocator),
        .planes = try Plane.generate_collection(allocator),
        .running = true,
        .last_frame = 0.0,
    };
}

fn vertex_specification(gl: *OpenGL) !void {
    const size = @sizeOf(f32);

    var buffer_obj: [2]u32 = [2]u32 {0, 0};
    var index_buffer_obj: [2]u32 = [2]u32 {0, 0};

    c.glGenVertexArrays(2, &gl.array_obj[0]);
    c.glBindVertexArray(gl.array_obj[0]);

    c.glGenBuffers(2, &buffer_obj[0]);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, buffer_obj[0]);
    c.glBufferData(c.GL_ARRAY_BUFFER, size * Cube.vertex_buffer.len, &Cube.vertex_buffer, c.GL_STATIC_DRAW);

    c.glGenBuffers(2, &index_buffer_obj[0]);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, index_buffer_obj[0]);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(u32) * Cube.index_buffer.len, &Cube.index_buffer, c.GL_STATIC_DRAW);

    const position_location: u32 = @bitCast(c.glGetAttribLocation(gl.shader_program, "position"));
    const color_location: u32 = @bitCast(c.glGetAttribLocation(gl.shader_program, "vertex_color"));

    if (position_location < 0 or color_location < 0) return error.AttribLocationNotFound;

    c.glEnableVertexAttribArray(position_location);
    c.glVertexAttribPointer(position_location, 3, c.GL_FLOAT, c.GL_FALSE, size * 6, @ptrFromInt(0));

    c.glEnableVertexAttribArray(color_location);
    c.glVertexAttribPointer(color_location, 3, c.GL_FLOAT, c.GL_FALSE, size * 6, @ptrFromInt(size * 3));

    c.glBindVertexArray(gl.array_obj[1]);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, buffer_obj[1]);
    c.glBufferData(c.GL_ARRAY_BUFFER, size * Plane.vertex_buffer.len, &Plane.vertex_buffer, c.GL_STATIC_DRAW);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, index_buffer_obj[1]);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(u32) * Plane.index_buffer.len, &Plane.index_buffer, c.GL_STATIC_DRAW);

    c.glEnableVertexAttribArray(position_location);
    c.glVertexAttribPointer(position_location, 3, c.GL_FLOAT, c.GL_FALSE, size * 6, @ptrFromInt(0));

    c.glEnableVertexAttribArray(color_location);
    c.glVertexAttribPointer(color_location, 3, c.GL_FLOAT, c.GL_FALSE, size * 6, @ptrFromInt(size * 3));

    c.glBindVertexArray(0);
    c.glDisableVertexAttribArray(color_location);
}

fn create_graphics_pipeline(gl: *OpenGL, allocator: Allocator) !void {
    var program_obj = c.glCreateProgram();

    const fragment_shader_content = try Io.read_file("assets/frag.glsl", allocator);
    const fragment_shader: u32 = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragment_shader, 1, &&fragment_shader_content[0], null);
    
    const vertex_shader_content = try Io.read_file("assets/vert.glsl", allocator);
    const vertex_shader: u32 = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertex_shader, 1, &&vertex_shader_content[0], null);

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
    const delta_time: f32 = (current_frame - gl.last_frame) / 1000.0;

    gl.last_frame = current_frame;

    _ = c.SDL_SetRelativeMouseMode(c.SDL_TRUE);
    c.SDL_WarpMouseInWindow(gl.window, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2);

    while (c.SDL_PollEvent(&event) != 0) {
        if (event.type == c.SDL_QUIT) {
            gl.running = false;
            break;
        } else if (event.type == c.SDL_MOUSEMOTION) {
            gl.camera.mouse(event.motion.xrel, event.motion.yrel);
        } else if (event.type == c.SDL_KEYDOWN) {
            const state: [*c]const u8 = c.SDL_GetKeyboardState(null);

            if (state[c.SDL_SCANCODE_SPACE] != 0) gl.camera.move_up(delta_time);
            if (state[c.SDL_SCANCODE_DOWN] != 0) gl.camera.move_down(delta_time);
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
    const color_location = c.glGetUniformLocation(gl.shader_program, "u_color_model");
    const model_location = c.glGetUniformLocation(gl.shader_program, "u_model");
    const rotation = math.Matrix.rotate(gl.last_frame * 0.1 * std.math.pi / 180.0, math.Vec.init(0.5, 1.0, 0.0));

    c.glBindVertexArray(gl.array_obj[0]);
    for (gl.cubes.items) |cube| {
        c.glUniformMatrix4fv(model_location, 1, c.GL_FALSE, &cube.model(rotation)[0][0]);
        c.glUniformMatrix4fv(color_location, 1, c.GL_FALSE, &cube.color[0][0]);
        c.glDrawElements(c.GL_TRIANGLES, Cube.number_of_triangles * 3, c.GL_UNSIGNED_INT, @ptrFromInt(0));
    }

    c.glBindVertexArray(gl.array_obj[1]);
    for (gl.planes.items) |plane| {
        c.glUniformMatrix4fv(model_location, 1, c.GL_FALSE, &plane.model()[0][0]);
        c.glUniformMatrix4fv(color_location, 1, c.GL_FALSE, &plane.color[0][0]);
        c.glDrawElements(c.GL_TRIANGLES, Plane.number_of_triangles * 3, c.GL_UNSIGNED_INT, @ptrFromInt(0));
    }
}

fn cleanup(gl: *OpenGL) !void {
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
    try cleanup(&gl);
}
