#version 460 core

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 vertex_color;

uniform mat4 u_model;
uniform mat4 u_projection;
uniform mat4 u_view;

out vec3 v_vertex_colors;

void main() {
    vec4 new_position = u_projection * u_view * u_model * vec4(position, 1.0f);

    v_vertex_colors = vertex_color;
    gl_Position = new_position;
}
