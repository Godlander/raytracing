#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;
uniform float GameTime;
uniform mat4 ProjMat;

in vec4 pos;
in mat3 viewmat;
in vec2 proj;
in vec2 rotation;

out vec4 fragColor;

#define FPRECISION 4000000.0
int intmod(int i, int base) {
    return i - (i / base * base);
}
vec3 encodeInt(int i) {
    int s = int(i < 0) * 128;
    i = abs(i);
    int r = intmod(i, 256);
    i = i / 256;
    int g = intmod(i, 256);
    i = i / 256;
    int b = intmod(i, 128);
    return vec3(float(r) / 255.0, float(g) / 255.0, float(b + s) / 255.0);
}
vec3 encodeFloat(float i) {
    return encodeInt(int(i * FPRECISION));
}
vec4 storepos(float f, int i) {
    if (i == 0) return vec4(floor(f) / 255.0, fract(f), fract(f * 255.0), 1);
    else return vec4(fract(f * 255 * 255), fract(f * 255 * 255 * 255), fract(f * 255 * 255 * 255), 1);
}
void main() {
    vec3 p = -(pos.xyz / pos.w) + 128.0; //turn relative coords backwards to act like world coords
    fragColor = vec4(0);
    ivec2 coord = ivec2(gl_FragCoord.xy);
    if (coord.y < 1) {
        switch (coord.x) {
            //6 pixels for x y z position
            case 0: case 1: case 2: case 3: case 4: case 5:
                fragColor = storepos(p[coord.x/2], coord.x%2);
                break;
            //3x3 view matrix
            case 6: case 7: case 8: case 9: case 10: case 11: case 12: case 13: case 14:
                fragColor = vec4(encodeFloat(viewmat[coord.x%3][(coord.x/3)-2]), 1);
                break;
            //proj[0][0] and proj[1][1]
            case 15: case 16:
                fragColor = vec4(encodeFloat(proj[coord.x%2]), 1);
                break;
        }
    } else discard;
}