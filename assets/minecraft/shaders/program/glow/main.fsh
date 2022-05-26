#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D MainSampler;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    fragColor = vec4(0);
    if (int(gl_FragCoord.x) < 4) {
        fragColor = texelFetch(MainSampler, ivec2(gl_FragCoord.x, 0), 0);
    }
}