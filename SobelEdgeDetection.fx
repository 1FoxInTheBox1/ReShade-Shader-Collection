
#include "Reshade.fxh"

uniform float _LineWeight < 
	ui_type="drag";
	ui_min = 0;
	ui_max = 10;
> = 1;

float sobel(float2 uv)
{
    float4 x, y;
    float2 texelSize = ReShade::PixelSize;
    x += tex2D(ReShade::BackBuffer, uv + float2(-texelSize.x, -texelSize.y)) * -1.0;
    x += tex2D(ReShade::BackBuffer, uv + float2(-texelSize.x, 0)) * -2.0;
    x += tex2D(ReShade::BackBuffer, uv + float2(-texelSize.x, texelSize.y)) * -1.0;

    x += tex2D(ReShade::BackBuffer, uv + float2(texelSize.x, -texelSize.y)) * 1.0;
    x += tex2D(ReShade::BackBuffer, uv + float2(texelSize.x, 0)) * 2.0;
    x += tex2D(ReShade::BackBuffer, uv + float2(texelSize.x, texelSize.y)) * 1.0;

    y += tex2D(ReShade::BackBuffer, uv + float2(-texelSize.x, -texelSize.y)) * -1.0;
    y += tex2D(ReShade::BackBuffer, uv + float2(0, -texelSize.y)) * -2.0;
    y += tex2D(ReShade::BackBuffer, uv + float2(texelSize.x, -texelSize.y)) * -1.0;

    y += tex2D(ReShade::BackBuffer, uv + float2(-texelSize.x, texelSize.y)) * 1.0;
    y += tex2D(ReShade::BackBuffer, uv + float2(0, texelSize.y)) * 2.0;
    y += tex2D(ReShade::BackBuffer, uv + float2(texelSize.x, texelSize.y)) * 1.0;
    
    x *= _LineWeight;
    y *= _LineWeight;
    
    return sqrt(x * x + y * y);
}

float3 SobelPS(float4 position : SV_POSITION, 
					float2 uv : TEXCOORD0) : SV_TARGET0 
{
    float3 edge = pow(sobel(uv), _LineWeight).xxx;
    return edge;
}

technique SobelEdgeDetection {
	pass pass1 {
		VertexShader = PostProcessVS;
		PixelShader = SobelPS;
	}
}