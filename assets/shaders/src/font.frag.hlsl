cbuffer Local : register(b0, space3) {
    float4 fill_color;
    float4 stroke_color;

    float stroke_blur;           // 0 - 1, best for shadows or glows.

    float rounded_fill;          // 0 for MSDF, 1 for SDF
    float rounded_stroke;        // 0 for MSDF, 1 for SDF

    float stroke_width_relative; // 0 - 0.7
    float stroke_width_absolute; // 0 - 50 in Screen Pixels, doesn't scale with font scale, great for consistent stroke thickness. Don't use it for text floating in 3d!

    float in_bias;               // 0
    float out_bias;              // 0.5 - 0 to 1

    float threshold;             // 0.1 - 0.9 without stroke, and 0.7 with stroke. Depends on stroke width. Controls thickness of the font.

    float2 unit_range;
    float2 aemrange;             // (minEm, maxEm)
}

struct Input
{
    float2 uv : TEXCOORD0;
};

Texture2D    msdf_atlas    : register(t0, space2);
SamplerState atlas_sampler : register(s0, space2);

#define GAMMA 1.5

float median(float3 v)
{
    return max(min(v.r, v.g),
           min(max(v.r, v.g), v.b));
}

// Reference:
// https://github.com/Chlumsky/msdfgen?tab=readme-ov-file#using-a-multi-channel-distance-field
float screen_px_range(float2 uv, float2 unit_range)
{
    float2 dx = ddx(uv);
    float2 dy = ddy(uv);

    float2 screenTexSize = rsqrt(dx * dx + dy * dy);

    return max(0.5 * dot(unit_range, screenTexSize), 1.0);
}

// Font Outline, Reference:
// https://www.redblobgames.com/x/2404-distance-field-effects/distance-field-effects.js
// https://www.redblobgames.com/x/2404-distance-field-effects/
// Features:
// Sharp or Rounded Font
// Thiccness Control
// Sharp or Rounded Outline
// Shadow
// Fast Premultiply Alpha Blendmode
// Antialiasing (https://drewcassidy.me/2020/06/26/sdf-antialiasing/)
float4 main(Input input) : SV_Target0 {
    float4 mtsdf = msdf_atlas.Sample(atlas_sampler, input.uv);

    float msdf = median(mtsdf.rgb);
    float sdf  = mtsdf.a;
    msdf       = min(msdf, sdf + 0.1);

    float fill   = lerp(msdf, sdf, rounded_fill  );
    float stroke = lerp(msdf, sdf, rounded_stroke);

    float width = screen_px_range(input.uv, unit_range);

    float inverted_threshold = 1.0 - threshold;
    float fill_coverage   = width * (fill   - inverted_threshold + in_bias) + out_bias;
    float stroke_coverage = width * (stroke - inverted_threshold + in_bias  + stroke_width_relative) + out_bias + stroke_width_absolute;

    float fill_opacity   = saturate(  fill_coverage);
    float stroke_opacity = saturate(stroke_coverage);

    float edge_alpha = stroke_color.a;

    if (stroke_blur > 0.0) {
        float blur_start = stroke_width_relative + stroke_width_absolute / width;
        edge_alpha       = smoothstep(blur_start,
                                    blur_start  * (1.0 - stroke_blur),
                                    inverted_threshold - sdf - out_bias  / width);
    }

    fill_opacity = pow(fill_opacity, 1.0 / GAMMA);

    float fill_alpha   = fill_color.a * fill_opacity;
    float stroke_alpha = edge_alpha   * saturate(stroke_opacity - fill_opacity);

    return float4(fill_color.rgb * fill_alpha + stroke_color.rgb * stroke_alpha, fill_alpha + stroke_alpha);
}

// Simple, no outline font rendering.
// Reference: https://github.com/Chlumsky/msdfgen?tab=readme-ov-file#using-a-multi-channel-distance-field
// float4 main(Input input) : SV_Target0 {
//     float4 sample = msdf_atlas.Sample(atlas_sampler, input.uv);
//     float msdf = median(sample.rgb);
//     float screen_px_distance = screen_px_range(input.uv, unit_range) * (msdf - 0.5);
//     float opacity = saturate(screen_px_distance + 0.5);
//     float alpha = fill_color.a * opacity;
//     return float4(fill_color.rgb * alpha, alpha);
// }
