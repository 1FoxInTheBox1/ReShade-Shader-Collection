
#include "Reshade.fxh"

uniform int framecount < source = "framecount"; >;

uniform float _Threshold < 
	ui_type="drag";
	ui_min = 0;
	ui_max = 1;
    ui_tooltip = "Pixels below this darkness will be omitted.";
> = 0;

uniform float _LineDarkness < 
	ui_type="drag";
	ui_min = 0;
	ui_max = 1;
    ui_tooltip = "The overall darkness of the lines.";
> = 1;

uniform float _FocusRange < 
	ui_type="drag";
	ui_min = 0;
	ui_max = 1;
    ui_tooltip = "The width of the focus area";
> = 1;

uniform float _FocalPlaneDistance < 
	ui_type="drag";
	ui_min = 0;
	ui_max = 1;
    ui_tooltip = "The distance the focal plane is from the camera.\n Higher values place the focal plane futher away";
> = 0.5;

uniform float _Detail <
    ui_type="drag";
	ui_min = 0;
	ui_max = 1;
    ui_tooltip = "How much out of focus objects should be drawn.\n Higher values will result in out of focus objects being drawn darker and in more detail";
> = 0;

texture2D bgTexture < source = "PaperBG.jpg"; >
{
    Width = 4500;
    Height = 3000;
    Format = RGBA8;
};

sampler2D bgTextureSampler { Texture = bgTexture; };

float sobel(float2 uv, float focus)
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
    
    x *= focus;
    y *= focus;
    
    return sqrt(x * x + y * y);
}

float getFocus(float depth) {
    float nearPlane = _FocalPlaneDistance + _FocusRange;
    float farPlane = _FocalPlaneDistance - _FocusRange;
    
    if (depth < farPlane)
    {
        return _Detail;
    }
    if (depth > nearPlane)
    {
        return _Detail;
    }
    float focus = 1- saturate((1 / _FocusRange) * abs(_FocalPlaneDistance - depth));
    return max(focus, _Detail);
}

float3 LineDrawingPS(float4 position : SV_POSITION,
                        float2 uv : TEXCOORD0) : SV_TARGET0
{
    float depth = ReShade::GetLinearizedDepth(uv);
    float focus = getFocus(depth);
    float3 color = saturate(sobel(uv, focus)).xxx;
    color = saturate(color * 2 * focus);
    color = color.x > _Threshold * 1/focus ? color.xxx : 0;
    color = clamp(color, 0, _LineDarkness);
    color = 1 - color;
    return color * tex2D(bgTextureSampler, uv);
}

technique LineDrawing
{
    pass pass1
    {
        VertexShader = PostProcessVS;
        PixelShader = LineDrawingPS;
    }
}