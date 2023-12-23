const std = @import("std");
const math = @import("math.zig");

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
    array_obj: c.GLuint,
    buffer_obj: c.GLuint,
    index_buffer_obj: c.GLuint,
    shader_program: c.GLuint,
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
        .running = true,
    };
}

fn vertex_specification(gl: *OpenGL) !void {
    const vertex_buffer = [_]f32 { 
        -1.0, -1.0, 0.0, 1.0, 0.0, 0.0,
        -1.0,  1.0, 0.0, 0.0, 1.0, 0.0,
         1.0,  1.0, 0.0, 0.0, 0.0, 1.0,
         1.0, -1.0, 0.0, 0.0, 0.0, 1.0
    };
    const index_buffer = [_]u32 {0, 2, 1, 3, 2, 0};
    const size = @sizeOf(f32);

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

    const vertex_shader: c.GLuint = c.glCreateShader(c.GL_VERTEX_SHADER);
    const fragment_shader: c.GLuint = c.glCreateShader(c.GL_FRAGMENT_SHADER);

    c.glShaderSource(vertex_shader, 1, &vertex_shader_program, null);
    c.glShaderSource(fragment_shader, 1, &fragment_shader_program, null);

    c.glCompileShader(vertex_shader);
    c.glCompileShader(fragment_shader);

    c.glAttachShader(program_obj, vertex_shader);
    c.glAttachShader(program_obj, fragment_shader);

    c.glLinkProgram(program_obj);

    gl.shader_program = program_obj;
}

fn input(gl: *OpenGL) void {
    var event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&event) != 0) {
        if (event.type == c.SDL_QUIT) {
            gl.running = false;
            break;
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
    var vec1 = math.Vec.init(4.0, 0.0, 0.0);
    var vec2 = math.Vec.init(0.0, 4.0, 0.0);
    std.debug.print("cross: {}\n", .{math.Vec.cross(vec1, vec2)});
    var gl = try initizlize();
    try vertex_specification(&gl);
    try create_graphics_pipeline(&gl);
    try loop(&gl);
    cleanup(gl);
}
