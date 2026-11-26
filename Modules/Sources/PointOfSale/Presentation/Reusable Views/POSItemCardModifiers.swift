import SwiftUI

extension EnvironmentValues {
    var posHidesItemCardImage: Bool {
        dynamicTypeSize.isAccessibilitySize && posLayoutScale == .compact
    }
}

private struct POSItemCardImageModifier: ViewModifier {
    @Environment(\.posHidesItemCardImage) private var hidesImage

    func body(content: Content) -> some View {
        content
            .renderedIf(!hidesImage)
    }
}

private struct POSItemCardTextPaddingModifier: ViewModifier {
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.posMetrics) private var metrics
    @Environment(\.posHidesItemCardImage) private var hidesImage

    private var multiplier: CGFloat {
        // The image is hidden at accessibility sizes, so the text sits on the card edge and needs the full padding.
        hidesImage ? 1 : 1 / scale
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
