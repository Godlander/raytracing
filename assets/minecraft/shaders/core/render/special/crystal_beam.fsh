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

uint encodeF(float f) { // From bálint
    uint sgn = f >= 0.0 ? 0u : 1u;
    uint exponent = uint(clamp(log2(abs(f)) + 127.0, 0.0, 255.0));
    uint mantissa = uint(abs(f) * exp2(-float(exponent) + 150.0)) & 8388607u;
    return (sgn << 31u) | (exponent << 23u) | mantissa;
}
vec4 encodepos(vec3 f, int coord) {
    uint val0 = encodeF(f.x);
    uint val1 = encodeF(f.y);
    uint val2 = encodeF(f.z);
    switch (coord) {
        case 0:
            return vec4(val0 >> 24u & 255u, val0 >> 16u & 255u, val0 >> 8u & 255u, 255)/255.0;
            break;
        case 1:
            return vec4(val0 & 255u, val1 >> 24u & 255u, val1 >> 16u & 255u, 255)/255.0;
            break;
        case 2:
            return vec4(val1 >> 8u & 255u, val1 & 255u, val2 >> 24u & 255u, 255)/255.0;
            break;
        case 3:
            return vec4(val2 >> 16u & 255u, val2 >> 8u & 255u, val2 & 255u, 255)/255.0;
            break;
        default:
            return vec4(0);
    }
}

int intmod(int i, int base) {return i - (i / base * base);}
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
vec3 encodeFloat(float i) {return encodeInt(int(i * 2000000.));}

void main() {
    vec3 p = -(pos.xyz / pos.w); //turn relative coords backwards to act like world coords
    fragColor = vec4(0);
    ivec2 coord = ivec2(gl_FragCoord.xy);
    if (coord.y < 1) {
        switch (coord.x) {
            //6 pixels for x y z position
            case 0: case 1: case 2: case 3:
                fragColor = encodepos(p, coord.x);
                break;
            //proj[0][0] and proj[1][1]
            case 4: case 5:
                fragColor = vec4(encodeFloat(proj[coord.x%2]), 1);
                break;
            //3x3 view matrix
            case 6: case 7: case 8: case 9: case 10: case 11: case 12: case 13: case 14:
                fragColor = vec4(encodeFloat(viewmat[coord.x%3][(coord.x/3)-2]), 1);
                break;
        }
    } else discard;
}