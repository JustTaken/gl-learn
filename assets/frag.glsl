#version 460 core

in vec3 v_vertex_color;

uniform mat4 u_color_model;

out vec4 color;

void main() {
    color = u_color_model * vec4(v_vertex_color, 1.0f);
}
