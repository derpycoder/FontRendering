#pragma clang diagnostic ignored "-Wmissing-prototypes"
#pragma clang diagnostic ignored "-Wmissing-braces"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

template<typename T, size_t Num>
struct spvUnsafeArray
{
    T elements[Num ? Num : 1];
    
    thread T& operator [] (size_t pos) thread
    {
        return elements[pos];
    }
    constexpr const thread T& operator [] (size_t pos) const thread
    {
        return elements[pos];
    }
    
    device T& operator [] (size_t pos) device
    {
        return elements[pos];
    }
    constexpr const device T& operator [] (size_t pos) const device
    {
        return elements[pos];
    }
    
    constexpr const constant T& operator [] (size_t pos) const constant
    {
        return elements[pos];
    }
    
    threadgroup T& operator [] (size_t pos) threadgroup
    {
        return elements[pos];
    }
    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup
    {
        return elements[pos];
    }
};

struct type_Global
{
    float4x4 viewProjectionMat;
};

struct SSBO
{
    float4x4 model_mat;
    float4 uv_rect;
    float4 plane_rect;
};

struct type_StructuredBuffer_SSBO
{
    SSBO _m0[1];
};

constant spvUnsafeArray<float2, 4> _40 = spvUnsafeArray<float2, 4>({ float2(0.0), float2(1.0, 0.0), float2(0.0, 1.0), float2(1.0) });
constant spvUnsafeArray<float2, 4> _41 = spvUnsafeArray<float2, 4>({ float2(0.0, 1.0), float2(1.0), float2(0.0), float2(1.0, 0.0) });

struct main0_out
{
    float2 out_var_TEXCOORD0 [[user(locn0)]];
    float4 gl_Position [[position]];
};

vertex main0_out main0(constant type_Global& Global [[buffer(0)]], const device type_StructuredBuffer_SSBO& ssbo [[buffer(1)]], uint gl_VertexIndex [[vertex_id]], uint gl_InstanceIndex [[instance_id]])
{
    main0_out out = {};
    out.gl_Position = Global.viewProjectionMat * (ssbo._m0[gl_InstanceIndex].model_mat * float4(ssbo._m0[gl_InstanceIndex].plane_rect.xy + (_40[gl_VertexIndex] * ssbo._m0[gl_InstanceIndex].plane_rect.zw), 0.0, 1.0));
    out.out_var_TEXCOORD0 = ssbo._m0[gl_InstanceIndex].uv_rect.xy + (_41[gl_VertexIndex] * ssbo._m0[gl_InstanceIndex].uv_rect.zw);
    return out;
}

