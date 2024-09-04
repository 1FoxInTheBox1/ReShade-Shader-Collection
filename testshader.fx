
#include "Reshade.fxh"

uniform int framecount < source = "framecount"; >;

uniform float4 Tint <
	ui_type = "color";
	ui_tooltip = "Color to tint the screen";
> = float4(1, 1, 1, 1);

uniform float FogIntensity <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 100;
> = 1;

float4 TestPixelShader(float4 position : SV_POSITION, 
						float2 uv : TEXCOORD0) : SV_TARGET0 {
	float3 depth = tex2D(ReShade::DepthBuffer, uv).xxx;
	float4 color = tex2D(ReShade::BackBuffer, uv);
	color *= Tint.rgb;
	depth = clamp(depth * FogIntensity, 0, 1);
	//return color * float4(depth, 0);
	return float4(depth, 0) * Tint;
}

technique TestShader {
	pass pass1 {
		VertexShader = PostProcessVS;
		PixelShader = TestPixelShader;
	}
}