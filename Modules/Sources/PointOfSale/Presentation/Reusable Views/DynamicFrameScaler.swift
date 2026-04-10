import SwiftUI

/// A view modifier that adjusts the width multiplier based on dynamic type size.
struct DynamicWidthScaler: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let containerWidth: CGFloat
    let threshold: DynamicTypeSize
    let smallSizeScale: CGFloat
    let largeSizeScale: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(width: containerWidth * widthMultiplier)
    }

    /// Returns a width multiplier based on the current dynamic type size
    private var widthMultiplier: CGFloat {
        dynamicTypeSize >= threshold ? largeSizeScale : smallSizeScale
    }
}

extension View {
    /// Applies a dynamic width scaling based on the current dynamic type size.
    /// - Parameters:
    ///   - containerWidth: The container width to scale.
    ///   - threshold: The dynamic type size threshold at which to switch from small to large scale (default: .accessibility2).
    ///   - smallSizeScale: The scale factor to apply for sizes smaller than the threshold (default: 0.5).
    ///   - largeSizeScale: The scale factor to apply for sizes larger than or equal to the threshold (default: 1.0).
    /// - Returns: A view with dynamically scaled width
    func dynamicWidthScaling(
        containerWidth: CGFloat,
        threshold: DynamicTypeSize = .accessibility2,
        smallSizeScale: CGFloat = 0.5,
        largeSizeScale: CGFloat = 1.0
    ) -> some View {
        modifier(DynamicWidthScaler(
            containerWidth: containerWidth,
            threshold: threshold,
            smallSizeScale: smallSizeScale,
            largeSizeScale: largeSizeScale
        ))
    }
}
