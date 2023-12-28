#version 460 core

in vec3 position;
in vec3 vertex_color;

uniform mat4 u_model;
uniform mat4 u_projection;
uniform mat4 u_view;

out vec3 v_vertex_color;

void main() {
    vec4 new_position = u_projection * u_view * u_model * vec4(position, 1.0f);

    v_vertex_color = vertex_color;
    gl_Position = new_position;
}
