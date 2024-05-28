#version 150

uniform sampler2D DiffuseSampler;

in vec4 Position;

uniform mat4 ProjMat;
uniform vec2 OutSize;
uniform vec2 InSize;

out vec2 texCoord;
flat out vec2 oneTexel;

out vec3 pos;
out vec2 proj;
out vec2 ratio;
out mat3 viewmat;

float decodeF(uint raw) { // From bálint
    uint sign = raw >> 31u;
    uint exponent = (raw >> 23u) & 255u;
    uint mantissa = 8388608u | (raw & 8388607u);
    return (float(sign) * -2.0 + 1.0) * float(mantissa) * exp2(float(exponent) - 150.0);
}
vec3 decodepos(int x, int y) {
    ivec3 n0 = ivec3(texelFetch(DiffuseSampler, ivec2(x  , y), 0).rgb * 255.);
    ivec3 n1 = ivec3(texelFetch(DiffuseSampler, ivec2(x+1, y), 0).rgb * 255.);
    ivec3 n2 = ivec3(texelFetch(DiffuseSampler, ivec2(x+2, y), 0).rgb * 255.);
    ivec3 n3 = ivec3(texelFetch(DiffuseSampler, ivec2(x+3, y), 0).rgb * 255.);
    return vec3(
        decodeF(uint(n0.x) << 24u | uint(n0.y) << 16u | uint(n0.z) << 8u | uint(n1.x)),
        decodeF(uint(n1.y) << 24u | uint(n1.z) << 16u | uint(n2.x) << 8u | uint(n2.y)),
        decodeF(uint(n2.z) << 24u | uint(n3.x) << 16u | uint(n3.y) << 8u | uint(n3.z))
    );
}
int decodeInt(vec3 ivec) {
    ivec *= 255.0;
    int s = ivec.b >= 128.0 ? -1 : 1;
    return s * (int(ivec.r) + int(ivec.g) * 256 + (int(ivec.b) - 64 + s * 64) * 256 * 256);
}
float decodemat(vec3 ivec) {return decodeInt(ivec) / 2000000.;}

void main() {
    float x = -1.0;
    float y = -1.0;
    if (Position.x > 0.001) x = 1.0;
    if (Position.y > 0.001) y = 1.0;

    gl_Position = vec4(x, y, 0.2, 1.0);
    texCoord = Position.xy / OutSize;
    oneTexel = 1.0 / OutSize;

    pos = decodepos(0,0);
    proj = vec2(decodemat(texelFetch(DiffuseSampler,ivec2(4,0),0).rgb), decodemat(texelFetch(DiffuseSampler,ivec2(5,0),0).rgb));
    viewmat = mat3(
        decodemat(texelFetch(DiffuseSampler,ivec2(6,0),0).rgb), decodemat(texelFetch(DiffuseSampler,ivec2(9,0),0).rgb),  decodemat(texelFetch(DiffuseSampler,ivec2(12,0),0).rgb),
        decodemat(texelFetch(DiffuseSampler,ivec2(7,0),0).rgb), decodemat(texelFetch(DiffuseSampler,ivec2(10,0),0).rgb), decodemat(texelFetch(DiffuseSampler,ivec2(13,0),0).rgb),
        decodemat(texelFetch(DiffuseSampler,ivec2(8,0),0).rgb), decodemat(texelFetch(DiffuseSampler,ivec2(11,0),0).rgb), decodemat(texelFetch(DiffuseSampler,ivec2(14,0),0).rgb)
    );
    ratio = vec2(OutSize.x / OutSize.y, 1.0);
}