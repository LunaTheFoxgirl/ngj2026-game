#include <metal_stdlib>
using namespace metal;

struct UniformIn {
    float4x4 viewProjection;
    float4 color;
};

struct VertexIn {
    float2 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant UniformIn& uniIn [[buffer(1)]]) {
    VertexOut out;

    // Extract camera facing.
    out.position = uniIn.viewProjection * float4(in.position, 0, 1);
    return out;
}

fragment float4 fragment_main(constant UniformIn& uniIn [[buffer(1)]]) {
    return uniIn.color;
}