#version 150

#moj_import <fog.glsl>
#moj_import <utils.glsl>

uniform sampler2D Sampler0;
uniform float GameTime;
uniform mat4 ProjMat;

in vec4 pos;
in mat3 viewmat;
in vec2 rotation;

out vec4 fragColor;

vec4 storefloat(float f) {
    return vec4(floor(f) / 255.0, fract(f), fract(f * 255.0), 1);
}

void main() {
    vec3 p = -(pos.xyz / pos.w) + 128.0; //turn relative coords backwards to act like world coords
    fragColor = vec4(0);
    if (all(lessThan(gl_FragCoord.xy, vec2(3.0, 4.0)))) {
        //3 pixels is x y z position
        if (int(gl_FragCoord.y) == 3) {
            fragColor = storefloat(p[int(gl_FragCoord.x)]);
        }
        else { //3x3 view matrix
            fragColor = vec4(encodeFloat(viewmat[int(gl_FragCoord.x)][int(gl_FragCoord.y)]), 1);
        }
    } else discard;
}