
#include "Reshade.fxh"

uniform int HorizontalSamples < 
	ui_type="drag";
	ui_min = 1;
	ui_max = 25;
> = 3;

uniform int VerticalSamples < 
	ui_type="drag";
	ui_min = 1;
	ui_max = 25;
> = 3;

uniform float Radius <
	ui_type = "drag";
	ui_min = 0;
	ui_max = 10;
> = 1;

float distanceFromCenter (float2 screenPos) {
	float2 center = float2(BUFFER_WIDTH / 2, BUFFER_HEIGHT / 2);
	return (pow(center.x - screenPos.x, 2) + pow(center.y - screenPos.y, 2)) / ((pow(center.x, 2) + pow(center.y, 2)) * Radius);
}

texture2D HorizontalBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
texture2D CombinedBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };

sampler2D HorizontalBufferSampler { Texture = HorizontalBuffer; };
sampler2D CombinedBufferSampler { Texture = CombinedBuffer; };

float4 BoxBlurHorizontalPS(float4 position : SV_POSITION, 
						float2 uv : TEXCOORD0) : SV_TARGET0 {
	float4 color = 0;
	for (int i = 0; i < HorizontalSamples; i++) {
		color += tex2D(ReShade::BackBuffer, uv + float2((i * ReShade::PixelSize.x),0));
	}
	return color / HorizontalSamples;
}

float4 BoxBlurVerticalPS(float4 position : SV_POSITION, 
						float2 uv : TEXCOORD0) : SV_TARGET0 {
	float4 color = 0;
	for (int i = 0; i < VerticalSamples; i++) {
		color += tex2D(HorizontalBufferSampler, uv + float2(0,(i * ReShade::PixelSize.y)));
	}
	return color / VerticalSamples;
}

float4 FinalRenderPS(float4 position : SV_POSITION,
					float2 uv : TEXCOORD0) : SV_TARGET0 {
	float4 original = tex2D(ReShade::BackBuffer, uv);
	float4 blurred = tex2D(CombinedBufferSampler, uv);
	return lerp(original, blurred, clamp(distanceFromCenter(position), 0, 1));
}


technique BoxBlur {
	pass HorizontalPass {
		VertexShader = PostProcessVS;
		PixelShader = BoxBlurHorizontalPS;
		RenderTarget = HorizontalBuffer;
	}

	pass VerticalPass {
		VertexShader = PostProcessVS;
		PixelShader = BoxBlurVerticalPS;
		RenderTarget = CombinedBuffer;
	}

	pass FinalPass {
		VertexShader = PostProcessVS;
		PixelShader = FinalRenderPS;
	}
}