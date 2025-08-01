//
//  WooShaderLibrary.metal
//  WooCommerce
//

#include <metal_stdlib>
using namespace metal;

// Basic linear interpolation between original and new color
[[stitchable]] half4 recolor(float2 position, half4 color, half4 newColor, float blendAmount) {
    return mix(color, newColor, half(blendAmount));
}
