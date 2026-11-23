import SwiftUI

/// Scales the content down until it fits the available height, so nothing is hidden below the fold.
/// Scrolls at accessibility text sizes, or when fitting would need a scale below `minimumScale`.
///
/// A plain scroll view proposes unlimited height, so flexible content (resizable images, `minimumScaleFactor`)
/// never shrinks inside it.
struct POSScaleToFitHeightModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let minimumScale: CGFloat

    /// Content height at full scale, never less than the available height (so Spacers fill when it fits).
    @State private var contentHeight: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { proxy in
            let availableHeight = proxy.size.height
            let measuredContent = content
                .frame(width: proxy.size.width)
                .frame(minHeight: availableHeight)
                .fixedSize(horizontal: false, vertical: true)
                // Paired with the available height so a pass repeating an earlier content height is still reported (iPhone Duo unfold).
                .onGeometryChange(for: HeightMeasurement.self, of: { HeightMeasurement(contentHeight: $0.size.height, availableHeight: availableHeight) }) {
                    contentHeight = $0.contentHeight
                }
            let scale = Self.scale(contentHeight: contentHeight, availableHeight: availableHeight)
            let shouldScroll = dynamicTypeSize.isAccessibilitySize || scale < minimumScale

            // Keep the content in one hierarchy so crossing the threshold preserves its state.
            ScrollView(.vertical, showsIndicators: false) {
                measuredContent
                    .scaleEffect(shouldScroll ? 1 : scale)
                    .frame(width: proxy.size.width, height: shouldScroll ? nil : availableHeight)
            }
            .scrollDisabled(!shouldScroll)
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private struct HeightMeasurement: Equatable {
        let contentHeight: CGFloat
        let availableHeight: CGFloat
    }

    nonisolated static func scale(contentHeight: CGFloat, availableHeight: CGFloat) -> CGFloat {
        guard contentHeight > availableHeight, contentHeight > 0 else {
            return 1
        }
        return availableHeight / contentHeight
    }
}

extension View {
    func posScaleToFitHeight(minimumScale: CGFloat = 0.5) -> some View {
        modifier(POSScaleToFitHeightModifier(minimumScale: minimumScale))
    }
}
