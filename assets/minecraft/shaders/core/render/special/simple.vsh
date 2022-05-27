#version 150

in vec3 Position;
in vec4 Color;
in vec2 UV0;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;
out vec4 lightColor;
out vec2 texCoord0;

#moj_import <common/head.vsh>
void main() {
#moj_import <common/main.vsh>
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    vertexColor = Color;
    lightColor = vec4(1);
    texCoord0 = UV0;
#moj_import <common/foot.vsh>
}