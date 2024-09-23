
#include "Reshade.fxh"

uniform int framecount < source = "framecount"; >;

uniform float KernelSize <
	ui_type = "drag";
	ui_min = 5.0; ui_max = 10;
> = 5;

struct RegionResult
{
    float3 mean;
	float variance;
};

RegionResult CalcRegion(float2 uv, float2 centerOffset, int boxSize) {
    RegionResult result;
	
    float3 squareSum = 0;
	float3 color = 0;
	for (int i = 0; i < boxSize; i++) {
	        for (int j = 0; j < boxSize; j++)
	        {
	            float2 pixelOffset = float2((i * ReShade::PixelSize.x), (j * ReShade::PixelSize.y));
	            color += tex2D(ReShade::BackBuffer, uv + (centerOffset * ReShade::PixelSize) + pixelOffset).rgb;
	            squareSum += color * color;
	        }
	}

    result.mean = (color / (boxSize * boxSize)).rgb;
	
    float3 variance = abs((squareSum / (boxSize * boxSize)) - (result.mean * result.mean));
    result.variance = length(variance);
	
    return result;
}

float3 KuwaharaPS(float4 position : SV_POSITION, 
						float2 uv : TEXCOORD0) : SV_TARGET0 {
    int boxSize = ceil(KernelSize / 2.0);
    RegionResult regionA = CalcRegion(uv, float2(boxSize, boxSize), boxSize);
    RegionResult regionB = CalcRegion(uv, float2(-boxSize, boxSize), boxSize);
    RegionResult regionC = CalcRegion(uv, float2(boxSize, -boxSize), boxSize);
    RegionResult regionD = CalcRegion(uv, float2(-boxSize, -boxSize), boxSize);
    
    // This block of code is from Daniel Ilett's
    // Image Effects tutorial series
    float minVar = regionA.variance;
    float3 col = regionA.mean;
    float testVal;

    testVal = step(regionB.variance, minVar);
    col = lerp(col, regionB.mean, testVal);
    minVar = lerp(minVar, regionB.variance, testVal);

    testVal = step(regionC.variance, minVar);
    col = lerp(col, regionC.mean, testVal);
    minVar = lerp(minVar, regionC.variance, testVal);

    testVal = step(regionD.variance, minVar);
    col = lerp(col, regionD.mean, testVal);
    
    return col;
}

technique Kuwahara {
	pass pass1 {
		VertexShader = PostProcessVS;
		PixelShader = KuwaharaPS;
	}
}
