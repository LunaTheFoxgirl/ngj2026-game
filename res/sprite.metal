#include <metal_stdlib>
using namespace metal;

struct UniformIn {
    float4x4 viewProjection;
};

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 uv       [[attribute(1)]];
    float4 color    [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
    float4 color;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant UniformIn& uniIn [[buffer(1)]]) {
    VertexOut out;

    // Extract camera facing.
    out.position = uniIn.viewProjection * float4(in.position, 0, 1);
    out.uv = in.uv;
    out.color = in.color;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]], sampler samplerIn [[sampler(0)]], texture2d<float> textureIn [[texture(0)]]) {
    return textureIn.sample(samplerIn, in.uv) * in.color;
}