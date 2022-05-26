#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>

in vec3 Position;
in vec2 UV0;
in vec4 Color;
in ivec2 UV2;

uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform int FogShape;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightColor;
out vec2 texCoord0;

flat out int isMarker;
flat out vec4 tint;

vec2[] corners = vec2[](
    vec2(0, 1), vec2(0, 0), vec2(1, 0), vec2(1, 1)
);

bool rougheq(vec2 a, vec2 b) {
    return all(lessThan(abs(a - b), vec2(0.01)));
}

#moj_import <common/head.vsh>
void main() {
#moj_import <common/main.vsh>
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    vertexDistance = fog_distance(ModelViewMat, Position, FogShape);
    texCoord0 = UV0;
    vertexColor = Color;
    lightColor = minecraft_sample_lightmap(Sampler2, UV2);

    isMarker = 0;
    tint = vec4(Color.rgb, 1.0);
    //particle minecraft:entity_effect ~ ~ ~ 0.1 0.2 0.0 1 0 force @s
    if (rougheq(Color.rg, vec2(0.1, 0.2))) {
        isMarker = 1;
        vec2 screenPos = 0.125 * corners[gl_VertexID % 4] - 1.0;
        gl_Position = vec4(screenPos, 0.0, 1.0);
    }

#moj_import <common/foot.vsh>
}