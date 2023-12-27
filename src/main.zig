const std = @import("std");
const math = @import("math.zig");
const util = @import("util.zig");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("glad/glad.h");
});

const Camera = util.Camera;
const APPLICATION_NAME = "OpenGL Window";
const SCREEN_WIDTH: isize = 640;
const SCREEN_HEIGHT: isize = 480;
var rotating: bool = true;

const OpenGL = struct {
    window: *c.SDL_Window,
    context: c.SDL_GLContext,
    array_obj: u32,
    shader_program: u32,
    u_rotate: f32,
    u_scale: f32,
    camera: Camera,
    running: bool,
};

fn initizlize() !OpenGL {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        return error.InitializeError;
    }

    const window = c.SDL_CreateWindow(APPLICATION_NAME, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, c.SDL_WINDOW_OPENGL) orelse return error.InitializeError;
    const context = c.SDL_GL_CreateContext(window) orelse return error.InitializeError;
    if (c.gladLoadGLLoader(c.SDL_GL_GetProcAddress) == 0) return error.InitializeErorr;

    return .{
        .window = window,
        .context = context,
        .array_obj = 0,
        .shader_program = 0,
        .u_rotate = 0.0,
        .u_scale = 0.5,
        .camera = util.Camera.default(),
        .running = true,
    };
}

fn vertex_specification(gl: *OpenGL) void {
    var buffer_obj: u32 = 0;
    var index_buffer_obj: u32 = 0;
    const size = @sizeOf(f32);
    const index_buffer = [_]u32 {0, 2, 1, 3, 2, 0};
    const vertex_buffer = [_]f32 { 
        -1.0, -1.0, 0.0, 1.0, 0.0, 0.0,
        -1.0,  1.0, 0.0, 0.0, 1.0, 0.0,
         1.0,  1.0, 0.0, 0.0, 0.0, 1.0,
         1.0, -1.0, 0.0, 0.0, 0.0, 1.0
    };

    c.glGenVertexArrays(1, &gl.array_obj);
    c.glBindVertexArray(gl.array_obj);

    c.glGenBuffers(1, &buffer_obj);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, buffer_obj);
    c.glBufferData(c.GL_ARRAY_BUFFER, size * vertex_buffer.len, &vertex_buffer, c.GL_STATIC_DRAW);

    c.glGenBuffers(1, &index_buffer_obj);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, index_buffer_obj);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(u32) * index_buffer.len, &index_buffer, c.GL_STATIC_DRAW);

    c.glEnableVertexAttribArray(0);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, size * 6, @ptrFromInt(0));

    c.glEnableVertexAttribArray(1);
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, size * 6, @ptrFromInt(size * 3));

    c.glBindVertexArray(0);
    c.glDisableVertexAttribArray(0);
    c.glDisableVertexAttribArray(1);
}

fn create_graphics_pipeline(gl: *OpenGL) !void {
    var program_obj = c.glCreateProgram();

    const vertex_shader: u32 = c.glCreateShader(c.GL_VERTEX_SHADER);
    const fragment_shader: u32 = c.glCreateShader(c.GL_FRAGMENT_SHADER);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

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
    c.SDL_WarpMouseInWindow(gl.window, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2);
    _ = c.SDL_SetRelativeMouseMode(c.SDL_TRUE);

    if (rotating) {
        gl.u_rotate -= 1.0;
    }
    while (c.SDL_PollEvent(&event) != 0) {
        if (event.type == c.SDL_QUIT) {
            gl.running = false;
            break;
        } else if (event.type == c.SDL_MOUSEMOTION) {
            gl.camera.mouse(event.motion.xrel, event.motion.yrel);
        } else if (event.type == c.SDL_KEYDOWN) {
            const state: [*c]const u8 = c.SDL_GetKeyboardState(null);
            if (state[c.SDL_SCANCODE_W] != 0) gl.camera.move_foward();
            if (state[c.SDL_SCANCODE_S] != 0) gl.camera.move_backward();
            if (state[c.SDL_SCANCODE_D] != 0) gl.camera.move_right();
            if (state[c.SDL_SCANCODE_A] != 0) gl.camera.move_left();
            if (state[c.SDL_SCANCODE_Q] != 0) {
                rotating = !rotating;
            }
        }
    }
}

fn pre_draw(gl: *OpenGL) void {
    c.glDisable(c.GL_DEPTH_TEST);
    c.glDisable(c.GL_CULL_FACE);
    c.glViewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    c.glClearColor(1.0, 1.0, 1.0, 1.0);
    c.glClear(c.GL_COLOR_BUFFER_BIT);
    c.glUseProgram(gl.shader_program);

    const translation: [4][4]f32 = math.Matrix.translate(0.0, 0.0, 0.0);
    const rotation = math.Matrix.rotate(gl.u_rotate * std.math.pi / 180.0, math.Vec.init(0.0, 1.0, 0.0));
    const scale = math.Matrix.scale(gl.u_scale, gl.u_scale, gl.u_scale);

    const projection: [4][4]f32 = math.Matrix.perspective(45.0 * std.math.pi / 180.0, @as(f32, SCREEN_WIDTH) / @as(f32, SCREEN_HEIGHT), 0.1, 100.0);
    const model = math.Matrix.mult(math.Matrix.mult(translation, rotation), scale);
    const view = gl.camera.view_matrix();

    const projection_location = c.glGetUniformLocation(gl.shader_program, "u_projection");
    const model_location = c.glGetUniformLocation(gl.shader_program, "u_model");
    const view_location = c.glGetUniformLocation(gl.shader_program, "u_view");

    c.glUniformMatrix4fv(projection_location, 1, c.GL_FALSE, &projection[0][0]);
    c.glUniformMatrix4fv(model_location, 1, c.GL_FALSE, &model[0][0]);
    c.glUniformMatrix4fv(view_location, 1, c.GL_FALSE, &view[0][0]);
}

fn draw(gl: *OpenGL) void {
    c.glBindVertexArray(gl.array_obj);
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, @ptrFromInt(0));
}

fn cleanup(gl: OpenGL) void {
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
    var gl = try initizlize();
    vertex_specification(&gl);
    try create_graphics_pipeline(&gl);
    try loop(&gl);
    cleanup(gl);
}
