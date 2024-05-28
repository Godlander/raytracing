#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in vec2 texCoord0;
in float vertexDistance;
in vec4 vertexColor;
in vec4 lightColor;

in vec3 pos;

out vec4 fragColor;

uint encodeF(float f) { // From bálint
    uint sgn = f >= 0.0 ? 0u : 1u;
    uint exponent = uint(clamp(log2(abs(f)) + 127.0, 0.0, 255.0));
    uint mantissa = uint(abs(f) * exp2(-float(exponent) + 150.0)) & 8388607u;
    return (sgn << 31u) | (exponent << 23u) | mantissa;
}
vec4 encodepos(vec3 f, int coord) {
    uint v0 = encodeF(f.x);
    uint v1 = encodeF(f.y);
    uint v2 = encodeF(f.z);
    switch (coord) {
        case 0: return vec4(v0 >>24u &255u, v0 >>16u &255u, v0 >>8u  &255u, 255)/255; break;
        case 1: return vec4(v0       &255u, v1 >>24u &255u, v1 >>16u &255u, 255)/255; break;
        case 2: return vec4(v1 >>8u  &255u, v1       &255u, v2 >>24u &255u, 255)/255; break;
        case 3: return vec4(v2 >>16u &255u, v2 >>8u  &255u, v2       &255u, 255)/255; break;
    }
    return vec4(0);
}

int intmod(int i, int base) {return i - (i / base * base);}
vec3 encodeI(int i) {
    int s = int(i < 0) * 128;
    i = abs(i);
    int r = intmod(i, 256);
    int g = intmod(i/256, 256);
    int b = intmod(i/65536, 128);
    return vec3(float(r) / 255.0, float(g) / 255.0, float(b + s) / 255.0);
}
vec3 encodemat(float i) {return encodeI(int(i * 2000000));}

void main() {
    vec4 color = texture(Sampler0, texCoord0);

    if (ivec4(color*255) == ivec4(12, 34, 56, 78)) {
        ivec2 coord = ivec2(gl_FragCoord.xy);
        if (coord.y == 0) switch (coord.x) {
            //4 pixels for x y z position
            case 0: case 1: case 2: case 3:
                fragColor = encodepos(pos, coord.x);
                break;
            //proj[0][0] and proj[1][1]
            case 4: case 5:
                vec2 proj = vec2(ProjMat[0][0],ProjMat[1][1]);
                fragColor = vec4(encodemat(proj[coord.x%2]), 1);
                break;
            //3x3 view matrix
            case 6: case 7: case 8: case 9: case 10: case 11: case 12: case 13: case 14:
                fragColor = vec4(encodemat(ModelViewMat[coord.x%3][(coord.x/3)-2]), 1);
                break;
            default: discard;
        }
        else discard; return;
    }

    if (color.a < 0.1) discard;
    color *= vertexColor * ColorModulator;
    color *= lightColor;
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}