cbuffer Global : register(b0, space1) {
  float4x4 viewProjectionMat;
};

struct SSBO {
  float4x4 model_mat;
  float4   uv_rect;
  float4   plane_rect;
};

StructuredBuffer<SSBO> ssbo : register(t0, space0);

struct Output {
  float4 clipPosition : SV_Position;
  float2 uv           : TEXCOORD0;
};

static const float2 unit_quad[4] = {
  float2(0.0, 0.0), // BL
  float2(1.0, 0.0), // BR
  float2(0.0, 1.0), // TL
  float2(1.0, 1.0)  // TR
};

static const float2 unit_uv[4] = {
  float2(0, 1),     // BL
  float2(1, 1),     // BR
  float2(0, 0),     // TL
  float2(1, 0)      // TR
};

Output main(uint vertexID : SV_VertexID, uint instanceID : SV_InstanceID) {
  SSBO data = ssbo[instanceID];

  float2 unit_pos = unit_quad[vertexID];
  float2 uv_pos   = unit_uv[vertexID];

  float2 local_pos = data.plane_rect.xy + unit_pos * data.plane_rect.zw;
  float2 local_uv  = data.uv_rect.xy    + uv_pos   * data.uv_rect.zw;

  float4 worldPosition = mul(data.model_mat,  float4(local_pos, 0, 1));

  Output output;
  output.clipPosition  = mul(viewProjectionMat, worldPosition);
  output.uv = local_uv;

  return output;
}
