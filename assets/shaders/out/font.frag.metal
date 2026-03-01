#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct type_Local
{
    float4 fill_color;
    float4 stroke_color;
    float stroke_blur;
    float rounded_fill;
    float rounded_stroke;
    float stroke_width_relative;
    float stroke_width_absolute;
    float in_bias;
    float out_bias;
    float threshold;
    float2 unit_range;
    float2 aemrange;
};

struct main0_out
{
    float4 out_var_SV_Target0 [[color(0)]];
};

struct main0_in
{
    float2 in_var_TEXCOORD0 [[user(locn0)]];
};

fragment main0_out main0(main0_in in [[stage_in]], constant type_Local& Local [[buffer(0)]], texture2d<float> msdf_atlas [[texture(0)]], sampler atlas_sampler [[sampler(0)]])
{
    main0_out out = {};
    float4 _49 = msdf_atlas.sample(atlas_sampler, in.in_var_TEXCOORD0);
    float _50 = _49.x;
    float _51 = _49.y;
    float _57 = _49.w;
    float _59 = precise::min(precise::max(precise::min(_50, _51), precise::min(precise::max(_50, _51), _49.z)), _57 + 0.100000001490116119384765625);
    float2 _68 = dfdx(in.in_var_TEXCOORD0);
    float2 _69 = dfdy(in.in_var_TEXCOORD0);
    float _76 = precise::max(0.5 * dot(Local.unit_range, rsqrt((_68 * _68) + (_69 * _69))), 1.0);
    float _79 = 1.0 - Local.threshold;
    float _116;
    if (Local.stroke_blur > 0.0)
    {
        float _109 = Local.stroke_width_relative + (Local.stroke_width_absolute / _76);
        _116 = smoothstep(_109, _109 * (1.0 - Local.stroke_blur), (_79 - _57) - (Local.out_bias / _76));
    }
    else
    {
        _116 = Local.stroke_color.w;
    }
    float _117 = powr(fast::clamp((_76 * ((mix(_59, _57, Local.rounded_fill) - _79) + Local.in_bias)) + Local.out_bias, 0.0, 1.0), 0.666666686534881591796875);
    float _121 = Local.fill_color.w * _117;
    float _124 = _116 * fast::clamp(fast::clamp(((_76 * (((mix(_59, _57, Local.rounded_stroke) - _79) + Local.in_bias) + Local.stroke_width_relative)) + Local.out_bias) + Local.stroke_width_absolute, 0.0, 1.0) - _117, 0.0, 1.0);
    float3 _131 = (Local.fill_color.xyz * _121) + (Local.stroke_color.xyz * _124);
    out.out_var_SV_Target0 = float4(_131, _121 + _124);
    return out;
}

