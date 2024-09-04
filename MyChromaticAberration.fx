
#include "Reshade.fxh"

uniform int framecount < source = "framecount"; >;

uniform float RedOffset <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
> = 0;

uniform float GreenOffset <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
> = 0;

uniform float BlueOffset <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
> = 0;

uniform float OffsetIntensity<
	ui_type = "drag";
	ui_min = 0; ui_max = 10.0;
> = 0;

uniform float Strength<
	ui_type = "drag";
	ui_min = 0; ui_max = 10.0;
> = 0;

float distanceFromCenter (float2 screenPos) {
	float2 center = float2(BUFFER_WIDTH / 2, BUFFER_HEIGHT / 2);
	return pow(center.x - screenPos.x, 2) + pow(center.y - screenPos.y, 2);
}

float3 ChromaticAberrationPS (float4 screenPos : SV_POSITION, 
								float2 uv : TEXCOORD0) : SV_TARGET0 {
	float3 color, original = tex2D(ReShade::BackBuffer, uv).rgb;
	float distance = distanceFromCenter(screenPos.xy) / distanceFromCenter(float2(0, 0));
	color.r = tex2D(ReShade::BackBuffer, uv + RedOffset * distance * OffsetIntensity).r;
	color.g = tex2D(ReShade::BackBuffer, uv + GreenOffset * distance * OffsetIntensity).g;
	color.b = tex2D(ReShade::BackBuffer, uv + BlueOffset * distance * OffsetIntensity).b;

	return lerp(original, color, Strength);
}

technique MyChromaticAberration {
	pass pass1 {
		VertexShader = PostProcessVS;
		PixelShader = ChromaticAberrationPS;
	}
}