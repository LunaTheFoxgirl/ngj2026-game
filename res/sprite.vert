#version 440

uniform Uniforms {
    mat4 viewProjections;
};

layout(location = 0) in Inputs {
    vec2 positionIn;
    vec2 uvIn;
    vec4 colorIn;
};

out Outputs {
    vec2 uvOut;
    vec2 colorOut;
};

void main() {
    gl_Position = uniformIn.viewProjection * vec4(position.xy, 0.0, 1.0);
    uvOut = uvIn;
    colorOut = colorIn;
}