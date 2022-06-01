#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

uniform mat4 ProjMat;
uniform mat3 IViewRotMat;

out vec4 pos;
out mat3 viewmat;
out vec2 proj;
out vec2 rotation;

const vec2[] corners = vec2[](
    vec2(0, 1), vec2(0, 0), vec2(1, 0), vec2(1, 1)
);

void main() {
    pos = vec4(0);
    viewmat = inverse(IViewRotMat);
    proj = vec2(ProjMat[0][0],ProjMat[1][1]);
    gl_Position = vec4(0); //make all faces disappear
    if (gl_VertexID == 0) { //only get position from first vertex
        pos = vec4(IViewRotMat * Position, 1);
    }
    if (gl_VertexID / 4 == 0) { //put that one face on screen for data
        vec2 screenPos = corners[gl_VertexID % 4]*2-1;
        gl_Position = vec4(screenPos, 0.0, 1.0);
    }
}
