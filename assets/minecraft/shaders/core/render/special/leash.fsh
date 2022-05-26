#version 150

#moj_import <fog.glsl>

uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
flat in vec4 vertexColor;

out vec4 fragColor;

#moj_import <common/head.fsh>
void main() {
#moj_import <common/main.fsh>
    fragColor = linear_fog(vertexColor, vertexDistance, FogStart, FogEnd, FogColor);
#moj_import <common/foot.fsh>
}