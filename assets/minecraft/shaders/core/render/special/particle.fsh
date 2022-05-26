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

out vec4 fragColor;

flat in int isMarker;
flat in vec4 tint;

#moj_import <common/head.fsh>
void main() {
#moj_import <common/main.fsh>
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * lightColor * ColorModulator;
    if (isMarker == 1) color = tint;
    if (color.a < 0.1) discard;
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);

#moj_import <common/foot.fsh>
}