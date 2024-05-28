#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D DepthSampler;
uniform sampler2D ImageSampler;
uniform vec2 OutSize;

in vec2 texCoord;

out vec4 fragColor;

in vec3 pos;
in vec2 proj;
in vec2 ratio;
in mat3 viewmat;

const float inf = uintBitsToFloat(0x7F800000u);

#define near 0.05
#define far 1000.0
float linearizeDepth(float depth) {
    float z = depth * 2.0 - 1.0;
    return (2.0 * near * far) / (far + near - z * (far - near));
}

vec4 Sphere(vec3 ro, vec3 rd, float r) {
    vec3 rc = -ro;
    float c = dot(rc, rc) - (r*r);
    float b = dot(rd, rc);
    float d = b * b - c;
    float t = -b - sqrt(abs(d));
    float st = step(0, min(t,d));
    t = mix(-1, t, st);
    if (t < 0) t = inf;
    vec3 norm = normalize(-ro+rd*t);
    return vec4(norm, t);
}

vec3 render(vec2 uv, float maindepth, vec3 col) {
    vec3 ro = pos;
    vec3 rd = vec3((uv*2-1) / proj, -1) * viewmat;
    float l = length(rd);
    rd /= l;
    maindepth = maindepth * l;
    vec3 position = ro + rd*maindepth;
    vec4 hit;

    //screenspace center
    vec3 clip = viewmat * ro;
    vec2 screencenter = (-clip.xy / clip.z  * proj + 1) / 2;
    //if (all(lessThan(abs((uv - screencenter) * ratio), vec2(0.01)))) return vec3(1,0,0);

    //center sphere
    hit = Sphere(ro, rd, 3);
    if (hit.w < maindepth) {
        col = vec3(1-dot(-rd, hit.xyz))/2 - 0.2;
        return col;
    }

    //distortion
    hit = Sphere(ro, rd, 7);
    if (hit.w < maindepth) {
        //push towards center
        vec2 dir = 0.2*normalize(uv - screencenter);
        float strength = dot(-rd, hit.xyz) * (atan(proj[1]) * l);
        uv = uv - dir * strength;
        uv.y = clamp(uv.y, 2/OutSize.y, 1);
        col = texture(ImageSampler, uv).rgb;
        return col;
    }

    return col;
}

void main() {
    vec2 uv = texCoord;
    uv.y = clamp(uv.y, 2/OutSize.y, 1);
    vec4 image = texture(ImageSampler, uv);
    float depth = linearizeDepth(texture(DepthSampler, texCoord).r);

    //render
    vec3 color = render(uv, depth, image.rgb);

    fragColor = vec4(color, 1);

    //debug pixels
    ivec2 coord = ivec2(gl_FragCoord.xy);
    if (all(lessThan(coord/10, ivec2(15,1)))) fragColor = texelFetch(DiffuseSampler, coord/10, 0);
}