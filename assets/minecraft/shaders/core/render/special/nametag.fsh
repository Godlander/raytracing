#version 150

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;

in vec4 vertexColor;
in vec4 lightColor;
in vec2 texCoord0;

out vec4 fragColor;

#moj_import <common/head.fsh>
void main() {
#moj_import <common/main.fsh>
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * lightColor;
    if (color.a < 0.1) discard;
    fragColor = color * ColorModulator;
#moj_import <common/foot.fsh>
}