#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

out vec4 fragColor;

#moj_import <common/head.fsh>
void main() {
#moj_import <common/main.fsh>
    vec4 color = texture(Sampler0, texCoord0) * vertexColor;
    fragColor = color * ColorModulator * linear_fog_fade(vertexDistance, FogStart, FogEnd);
#moj_import <common/foot.fsh>
}