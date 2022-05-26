#version 150

uniform sampler2D DiffuseSampler;

in vec4 Position;

uniform mat4 ProjMat;
uniform vec2 OutSize;
uniform vec2 InSize;

out vec2 texCoord;
flat out vec2 oneTexel;
out vec3 position;
out mat3 viewmat;
out vec2 ratio;
flat out int nobjs;

#define FPRECISION 4000000.0
int decodeInt(vec3 ivec) {
    ivec *= 255.0;
    int s = ivec.b >= 128.0 ? -1 : 1;
    return s * (int(ivec.r) + int(ivec.g) * 256 + (int(ivec.b) - 64 + s * 64) * 256 * 256);
}
float decodeFloat(vec3 ivec) {
    return decodeInt(ivec) / FPRECISION;
}
void main() {
    float x = -1.0;
    float y = -1.0;
    if (Position.x > 0.001) x = 1.0;
    if (Position.y > 0.001) y = 1.0;

    position = (vec3(255.0, 1.0, 1.0 / 255.0) * mat3(
        texelFetch(DiffuseSampler, ivec2(0,3), 0).rgb,
        texelFetch(DiffuseSampler, ivec2(1,3), 0).rgb,
        texelFetch(DiffuseSampler, ivec2(2,3), 0).rgb)) - 128;
    viewmat = mat3(
        decodeFloat(texelFetch(DiffuseSampler, ivec2(0,0), 0).rgb), decodeFloat(texelFetch(DiffuseSampler, ivec2(1,0), 0).rgb), decodeFloat(texelFetch(DiffuseSampler, ivec2(2,0), 0).rgb),
        decodeFloat(texelFetch(DiffuseSampler, ivec2(0,1), 0).rgb), decodeFloat(texelFetch(DiffuseSampler, ivec2(1,1), 0).rgb), decodeFloat(texelFetch(DiffuseSampler, ivec2(2,1), 0).rgb),
        decodeFloat(texelFetch(DiffuseSampler, ivec2(0,2), 0).rgb), decodeFloat(texelFetch(DiffuseSampler, ivec2(1,2), 0).rgb), decodeFloat(texelFetch(DiffuseSampler, ivec2(2,2), 0).rgb)
    );
    ratio = vec2(OutSize.x / OutSize.y, 1.0);

    ivec4 objmeta = ivec4(texelFetch(DiffuseSampler, ivec2(0,4), 0)*255);
    nobjs = 0;
    if (objmeta.gba == ivec3(0,0,255)) {
        nobjs = objmeta.r+1;
    }

    gl_Position = vec4(x, y, 0.2, 1.0);
    texCoord = Position.xy / OutSize;
    oneTexel = 1.0 / OutSize;
}