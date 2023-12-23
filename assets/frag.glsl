#version 460 core

in vec3 v_vertex_colors;
out vec4 color;

void main() {
    color = vec4(v_vertex_colors.r, v_vertex_colors.g, v_vertex_colors.b, 1.0f);
}
