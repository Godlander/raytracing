#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>

uniform sampler2D Sampler0;

in vec3 Position;
in vec2 UV0;
in vec3 Normal;

uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec2 texCoord0;

flat out int shape;
flat out int id;
out vec3 position;

const vec2[] corners = vec2[](
    vec2(0, 1), vec2(0, 0), vec2(1, 0), vec2(1, 1)
);

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    texCoord0 = UV0;

    shape = 0;
    id = 0;
    ivec4 col = ivec4(textureLod(Sampler0, UV0, 0)*255);
    if (col.rgb == ivec3(12,34,56)) {
        shape = col.a;
        id = gl_VertexID / 4;
        vec2 screenPos = corners[gl_VertexID % 4]*2-1;
        gl_Position = vec4(screenPos, 0.0, 1.0);
        position = -(IViewRotMat * Position) + 128;
    }
}