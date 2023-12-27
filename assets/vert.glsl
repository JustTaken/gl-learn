#version 460 core

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 vertex_color;

uniform mat4 u_model;
uniform mat4 u_projection;

out vec3 v_vertex_colors;

void main() {
    v_vertex_colors = vertex_color;
    vec4 new_position = u_projection * u_model * vec4(position, 1.0f);
    gl_Position = new_position;
}
