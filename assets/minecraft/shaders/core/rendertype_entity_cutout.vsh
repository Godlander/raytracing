#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform int FogShape;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out vec2 texCoord0;
out float vertexDistance;
out vec4 vertexColor;
out vec4 lightColor;

out vec3 pos;

const vec2[] corners = vec2[](vec2(0, 1), vec2(0, 0), vec2(1, 0), vec2(1, 1));

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vertexDistance = fog_distance(Position, FogShape);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    lightColor = minecraft_sample_lightmap(Sampler2, UV2);
    texCoord0 = UV0;

    if (ivec4(texture(Sampler0, UV0)*255) == ivec4(12, 34, 56, 78)) {
        gl_Position = vec4(corners[gl_VertexID]/10-1,-1,1);
        pos = Position;
    }
}