#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

in vec2 texCoord0;
flat in int shape;
flat in int id;

out vec4 fragColor;
in vec3 position;

vec4 storefloat(float f) {
    return vec4(floor(f) / 255.0, fract(f), fract(f * 255.0), 1);
}
void main() {
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a < 0.1) discard;
    fragColor = color;

    ivec2 coord = ivec2(gl_FragCoord.xy);
    if (coord.y == 2 && coord.x < (id+1)*3) {
        if (coord.x == 0) {
            fragColor = vec4(id/255.,0,0,1);
        }
        else if (coord.x/3 == id+1) {
            fragColor = storefloat(position[coord.x % 3]);
        }
        else discard;
    }
}