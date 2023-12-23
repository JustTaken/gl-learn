const std = @import("std");
const math = @import("math.zig");
const util = @import("util.zig");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("glad/glad.h");
});

const SCREEN_WIDTH: isize = 640;
const SCREEN_HEIGHT: isize = 480;

const vertex_shader_program: [*c]const u8 = "#version 460 core\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec3 vertex_color;\nout vec3 v_vertex_colors;\nvoid main()\n{\nv_vertex_colors = vertex_color;\ngl_Position = vec4(position.x, position.y, position.z, 1.0f);\n}\n";
const fragment_shader_program: [*c]const u8 = "#version 460 core\nin vec3 v_vertex_colors;\nout vec4 color;\nvoid main()\n{\ncolor = vec4(v_vertex_colors.r, v_vertex_colors.g, v_vertex_colors.b, 1.0f);\n}\n";

const OpenGL = struct {
    window: *c.SDL_Window,
    context: c.SDL_GLContext,
    array_obj: u32,
    buffer_obj: u32,
    index_buffer_obj: u32,
    shader_program: u32,
    u_offset: f32,
    running: bool,
};

fn initizlize() !OpenGL {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        return error.InitializeError;
    }

    const window = c.SDL_CreateWindow("OpenGL window", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, c.SDL_WINDOW_OPENGL) orelse return error.InitializeError;
    const context = c.SDL_GL_CreateContext(window) orelse return error.InitializeError;
    if (c.gladLoadGLLoader(c.SDL_GL_GetProcAddress) == 0) return error.InitializeErorr;

    return .{
        .window = window,
        .context = context,
        .array_obj = 0,
        .buffer_obj = 0,
        .shader_program = 0,
        .index_buffer_obj = 0,
        .u_offset = 0.0,
        .running = true,
    };
}

fn vertex_specification(gl: *OpenGL) !void {
    const size = @sizeOf(f32);
    const index_buffer = [_]u32 {0, 2, 1, 3, 2, 0};
    const vertex_buffer = [_]f32 { 
        -0.5, -0.5, 0.0, 1.0, 0.0, 0.0,
        -0.5,  0.5, 0.0, 0.0, 1.0, 0.0,
         0.5,  0.5, 0.0, 0.0, 0.0, 1.0,
         0.5, -0.5, 0.0, 0.0, 0.0, 1.0
    };

    c.glGenVertexArrays(1, &gl.array_obj);
    c.glBindVertexArray(gl.array_obj);

    c.glGenBuffers(1, &gl.buffer_obj);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, gl.buffer_obj);
    c.glBufferData(c.GL_ARRAY_BUFFER, size * vertex_buffer.len, &vertex_buffer, c.GL_STATIC_DRAW);

    c.glGenBuffers(1, &gl.index_buffer_obj);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, gl.index_buffer_obj);
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

    // var result: i32 = 0;
    // c.glGetShaderiv(vertex_shader, c.GL_COMPILE_STATUS, &result);
    // if (result == c.GL_FALSE) {
    //     var length: i32 = 0;
    //     c.glGetShaderiv(vertex_shader, c.GL_INFO_LOG_LENGTH, &length);
    //     var message: [100]u8 = undefined;
    //     c.glGetShaderInfoLog(vertex_shader, length, &length, &message[0]);
    //     std.debug.print("{s}\n", .{message});
    // }

    c.glAttachShader(program_obj, fragment_shader);
    c.glAttachShader(program_obj, vertex_shader);

    c.glLinkProgram(program_obj);
    c.glValidateProgram(program_obj);

    gl.shader_program = program_obj;
}

fn input(gl: *OpenGL) void {
    var event: c.SDL_Event = undefined;

    while (c.SDL_PollEvent(&event) != 0) {
        if (event.type == c.SDL_QUIT) {
            gl.running = false;
            break;
        }

        const state: [*c]const u8 = c.SDL_GetKeyboardState(null);
        if (state[c.SDL_SCANCODE_UP] != 0) {
            std.debug.print("UP\n", .{});
            gl.u_offset += 0.01;
        }

        if (state[c.SDL_SCANCODE_DOWN] != 0) {
            std.debug.print("DOWN\n", .{});
            gl.u_offset -= 0.01;
        }
    }
}

fn pre_draw(gl: *OpenGL) void {
    c.glDisable(c.GL_DEPTH_TEST);
    c.glDisable(c.GL_CULL_FACE);
    c.glViewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    c.glClearColor(1.0, 1.0, 0.0, 1.0);
    c.glClear(c.GL_DEPTH_BUFFER_BIT | c.GL_COLOR_BUFFER_BIT);
    c.glUseProgram(gl.shader_program);

    const model: [4][4]f32 = math.Matrix.translate(0.0, gl.u_offset, 0.0);
    const model_location = c.glGetUniformLocation(gl.shader_program, "u_model_matrix");
    const perspective_location = c.glGetUniformLocation(gl.shader_program, "u_perspective_matrix");
    _ = perspective_location;

    if (model_location >= 0) {
        c.glUniformMatrix4fv(model_location, 1, c.GL_FALSE, &model[0][0]);
        std.debug.print("{d}\n", .{model});
    }
}

fn draw(gl: *OpenGL) void {
    c.glBindVertexArray(gl.array_obj);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, gl.buffer_obj);
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
    try vertex_specification(&gl);
    try create_graphics_pipeline(&gl);
    try loop(&gl);
    cleanup(gl);
}
