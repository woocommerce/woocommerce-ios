import SwiftUI

/// Scales the content down until it fits the available height, so nothing is hidden below the fold.
/// Scrolls instead when fitting would need a scale below `minimumScale`, e.g. with accessibility text sizes.
///
/// A plain scroll view proposes unlimited height, so flexible content (resizable images, `minimumScaleFactor`)
/// never shrinks inside it.
struct POSScaleToFitHeightModifier: ViewModifier {
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
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { contentHeight = $0 }
            let scale = Self.scale(contentHeight: contentHeight, availableHeight: availableHeight)

            if scale >= minimumScale {
                measuredContent
                    .scaleEffect(scale)
                    .frame(width: proxy.size.width, height: availableHeight)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    measuredContent
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
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
