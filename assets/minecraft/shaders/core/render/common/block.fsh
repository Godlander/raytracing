#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightColor;
in vec2 texCoord0;
in vec4 normal;

out vec4 fragColor;

#moj_import <common/head.fsh>
void main() {
#moj_import <common/main.fsh>
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * lightColor * ColorModulator;
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
#moj_import <common/foot.fsh>
}