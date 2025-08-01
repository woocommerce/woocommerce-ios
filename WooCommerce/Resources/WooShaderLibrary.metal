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

// Animated recolor with pulsing effect
// only affecting non-transparent pixels
[[ stitchable ]] half4 recolorAnimated(float2 pos, half4 color, half4 newColor, float time) {
    if (color.a > 0.0) {
        // Create a pulsing effect that oscillates between 0 and 1
        float pulse = (sin(time * 3.0) + 1.0) * 0.5; // Oscillates between 0 and 1
        
        // Use the pulse as the blend amount for dynamic effect
        half3 blended = mix(color.rgb, newColor.rgb, half(pulse));
        return half4(blended, color.a);
    } else {
        return color; // Keep transparent pixels transparent
    }
}
