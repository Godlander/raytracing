#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D DepthSampler;
uniform sampler2D StorageSampler;

uniform vec2 OutSize;

in vec2 texCoord;
in vec2 OneTexel;
in vec2 ratio;
in vec3 position;
in mat3 viewmat;
in vec2 proj;
flat in int nobjs;

out vec4 fragColor;

#define AA 1
//#define DEBUG

#define renderdistance 80
#define fogstart 40

#define PI 3.14159265358979323846

#define FPRECISION 4000000.0
int decodeInt(vec3 ivec) {
    ivec *= 255.0;
    int s = ivec.b >= 128.0 ? -1 : 1;
    return s * (int(ivec.r) + int(ivec.g) * 256 + (int(ivec.b) - 64 + s * 64) * 256 * 256);
}
float decodeFloat(vec3 ivec) {
    return decodeInt(ivec) / FPRECISION;
}
#define near 0.05
#define far  1000.0
float linearizeDepth(float depth) {
    float z = depth * 2.0 - 1.0;
    return (2.0 * near * far) / (far + near - z * (far - near));
}
//--------------------------------------------------------------------------------
//sdfs
struct obj {float depth; int type;};
obj Plane   (vec3 p,                int type) {return obj(p.y, type);}
obj Sphere  (vec3 p, float r,       int type) {return obj(length(p)-r, type);}
obj Cube    (vec3 p, vec3 b,        int type) {
    vec3 d = abs(p) - b;
    return obj(max(d.x, max(d.y, d.z)), type);
}
//--------------------------------------------------------------------------------
//operations
obj Add(obj a, obj b) {return a.depth < b.depth? a : b;}
obj Sub(obj a, obj b) {return -a.depth > b.depth? a : b;}
obj Intersect(obj a, obj b) {return a.depth > b.depth? a : b;}
obj SmoothAdd(obj a, obj b, float k) {
    float h = clamp(0.5 + 0.5*(b.depth-a.depth)/k, 0.0, 1.0);
    return obj(mix(b.depth, a.depth, h) - k*h*(1.0-h), a.type);
}
obj SmoothSub(obj a, obj b, float k) {
    float h = clamp(0.5 - 0.5*(a.depth+b.depth)/k, 0.0, 1.0);
    return obj(mix(a.depth, -b.depth, h) + k*h*(1.0-h), a.type);
}
obj SmoothIntersect(obj a, obj b, float k) {
    float h = clamp(0.5 - 0.5*(b.depth-a.depth)/k, 0.0, 1.0);
    return obj(mix(b.depth, a.depth, h) + k*h*(1.0-h), a.type);
}
//--------------------------------------------------------------------------------
obj hit(in vec3 pos) {//obj     pos                     size                    material    smoothness
    obj o =             Plane(  pos + 2,                                        1);
    o = SmoothAdd(o,    Sphere( pos + vec3(0,2.5,0),    2,                      1),         0.5);
    o = SmoothSub(o,    Sphere( pos + vec3(-2,1.5,0),   2,                      1),         0.5);
    o = Add(o,          Sphere( pos + vec3(2,1,4),      1,                      2));
    o = Add(o,          Cube(   pos + vec3(5,1,1),      vec3(1),                3));
    o = SmoothAdd(o,    Sphere( pos + vec3(5.5,0.5,.5), 1,                      3),         0.5);

    //add 20 spheres
    for (int i = 0; i < 20; i++) {
        float r = 1 + 0.5*sin(i*PI/10.0);
        o = Add(o, Sphere(pos + 8*vec3(r*cos(i*PI/10.0), -1, r*sin(i*PI/10.0)), r, 2));
    }

    for (int i = 0; i < nobjs; i++) {
        o = Add(o,  Sphere( pos - position + ((vec3(255.0, 1.0, 1.0 / 255.0) * mat3(
                        texelFetch(DiffuseSampler, ivec2(3*i + 3,4), 0).rgb,
                        texelFetch(DiffuseSampler, ivec2(3*i + 4,4), 0).rgb,
                        texelFetch(DiffuseSampler, ivec2(3*i + 5,4), 0).rgb)) - 128), 1, 2));
    }
    return o;
}

//--------------------------------------------------------------------------------
//filters
float checkerboard(in vec2 p) {
    // filter kernel
    vec2 w = max(abs(dFdx(p)), abs(dFdy(p))) + 0.01;
    // analytical integral (box filter)
    vec2 i = 2.0*(abs(fract((p-0.5*w)/2.0)-0.5)-abs(fract((p+0.5*w)/2.0)-0.5))/w;
    // xor pattern
    return 0.5 - 0.5*i.x*i.y;
}
float shadows(in vec3 ro, in vec3 rd, in float tmin, in float tmax) {
    float vol = (0.8-ro.y)/rd.y;
    if (vol > 0.0) tmax = min(tmax, vol);
    float res = 1.0;
    float t = tmin;
    for(int i = 0; i < 50; i++) {
        float h = hit(ro + rd*t).depth;
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min(res, s*s*(3.0-2.0*s));
        t += clamp(h, 0.02, 0.2);
        if (res < 0.005 || t > tmax) break;
    }
    return clamp(res, 0.3, 1.0);
    //float vol = (0.8-ro.y)/rd.y;
    //if (vol > 0.0) tmax = min(tmax, vol);
    //float res = 1.0;
    //float t = tmin;
    //for(int i = 0; i < 50; i++) {
    //    float h = hit(ro + rd*t).depth;
    //    float s = clamp(8.0*h/t,0.0,1.0);
    //    res = min(res, s*s*(3.0-2.0*s));
    //    t += clamp(h, 0.02, 0.2);
    //    if (res < 0.004 || t > tmax) break;
    //}
    //return clamp(res, 0.3, 1.0);
}
float AO(in vec3 pos, in vec3 norm) {
    float occ = 0.0;
    float sca = 1.0;
    for(int i=0; i<5; i++) {
        float h = 0.01 + 0.12*float(i)/5.0;
        float d = hit(pos + norm*h).depth;
        occ += (h-d)*sca;
        sca *= 0.95;
        if(occ > 0.35) break;
    }
    return clamp(1.0 - 3.0 * occ, 0.0, 1.0) * (0.5 + 0.5 * norm.y);
}
//--------------------------------------------------------------------------------

vec3 getnormal(in vec3 pos) {
    vec2 e = vec2(0.001,0);
    return normalize(vec3(hit(pos+e.xyy).depth-hit(pos-e.xyy).depth,
                          hit(pos+e.yxy).depth-hit(pos-e.yxy).depth,
                          hit(pos+e.yyx).depth-hit(pos-e.yyx).depth));
}
vec3 render(vec3 ro, vec3 rd, float fardepth, vec3 maincolor) {
    //raymarching
    float t = 0.;
    obj o;
    for(int i = 0; i < 100; i++) {
        o = hit(ro + t*rd);
        //if (h.depth < o.depth) o = h;
        //if hit
        if (o.depth < 0.001) break;
        t += o.depth;
        //exceed far plane
        if (t >= fardepth) break;
    }
    //coloring
    vec3 sky = vec3(0.7, 0.9, 1.1);
    vec3 sunlight = vec3(0.5,0.4,0.3);
    //fake atmosphere by dimming up
    vec3 color = sky - max(rd.y,0.0)*0.3;
    vec3 sundir = normalize(vec3(-0.5, 0.4, -0.6));
    float sun = clamp(dot(sundir,rd), 0.0, 1.0);
    if (t < fardepth) {
        vec3 pos = ro + t*rd;
        vec3 norm = getnormal(pos);
        float shadow = shadows(pos, sundir, 0.01, 3);
        //materials
        switch(o.type) {
            case 1: //plane
                color = vec3(checkerboard(pos.xz) + 0.5);
                color *= shadow;
                break;
            case 2: //sphere
                color = vec3(0.6, 0.3, 0.4);
                color += dot(norm, sundir) * sunlight;
                break;
            default: color = (norm+1)/2;
        }
        color = clamp(color, 0.0, 1.0);
        color *= AO(pos, norm);
        //fog
        color = mix(color, sky, smoothstep(0,1, clamp((t-fogstart)/(renderdistance-fogstart) ,0,1)));
    }
    else if (t < renderdistance) {
        color = maincolor;
        color = mix(color, sky, smoothstep(0,1, clamp((fardepth-fogstart)/(renderdistance-fogstart) ,0,1)));
    }
    //sun glare
    color += 0.25*vec3(0.8,0.4,0.2)*pow(sun, 4.0);
    return color;
}
void main() {
    //data
    vec3 color = vec3(0);
    vec3 maincolor = texture(DiffuseSampler, texCoord).rgb;
    float depth = linearizeDepth(texture(DepthSampler, texCoord).r);

//msaa
#if AA > 1
for(int m=0; m<AA; m++)
for(int n=0; n<AA; n++) {
    // pixel coordinates
    vec2 offset = (vec2(float(m),float(n)) / float(AA) - 0.5) * 2 / OutSize;
    vec2 uv = (texCoord * 2 - 1) + offset;
#else
    vec2 uv = (texCoord * 2 - 1);
#endif

    //ray start
    vec3 ro = position;
    vec3 rd = viewmat * vec3(uv/proj,-1);
    //warp depth to fov
    float l = length(rd);
    rd /= l;
    depth = depth * l;
    //render
    color += render(ro, rd, min(depth, renderdistance), maincolor);

#if AA > 1
}
color /= float(AA*AA);
#endif

    fragColor = vec4(color, 1);

//debug data pixels bottom left
#ifdef DEBUG
    #define datasize vec3(32,5, 10)
    if (all(lessThan(gl_FragCoord.xy / datasize.z, datasize.xy))) {
      fragColor = texelFetch(DiffuseSampler, ivec2(gl_FragCoord.xy / datasize.z), 0);
    }
#endif
}