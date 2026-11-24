import SwiftUI

private struct POSItemCardImageModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content
            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
    }
}

private struct POSItemCardTextPaddingModifier: ViewModifier {
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.posMetrics) private var metrics
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var multiplier: CGFloat {
        // The image is hidden at accessibility sizes, so the text sits on the card edge and needs the full padding.
        dynamicTypeSize.isAccessibilitySize ? 1 : 1 / scale
    }

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, metrics.padding.medium * multiplier)
            .padding(.vertical, metrics.padding.small * multiplier)
    }
}

extension View {
    func posItemCardImage() -> some View {
        modifier(POSItemCardImageModifier())
    }

    func posItemCardTextPadding() -> some View {
        modifier(POSItemCardTextPaddingModifier())
    }
}
