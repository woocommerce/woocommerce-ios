//
//  WooShaderLibrary.metal
//  WooCommerce
//

#include <metal_stdlib>
using namespace metal;

// Basic linear interpolation between original and new color
// only affecting non-transparent pixels
[[ stitchable ]] half4 recolor(float2 pos, half4 color, half4 newColor, float blendAmount) {
    if (color.a > 0.0) {
        // Blend original color with the provided overlay color
        half3 blended = mix(color.rgb, newColor.rgb, half(blendAmount));
        return half4(blended, color.a);
    } else {
        return color; // Keep transparent pixels transparent
    }
}
