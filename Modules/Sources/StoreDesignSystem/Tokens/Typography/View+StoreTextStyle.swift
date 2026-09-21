import SwiftUI
import UIKit

public extension View {
    /// Applies a design-system text style (font, weight, line height, tracking) that
    /// scales with Dynamic Type. Bold Text (Settings → Accessibility) is handled natively:
    /// SwiftUI resolves system fonts one weight heavier when the setting is on, so no
    /// manual weight mapping is needed (adding one would double-apply the emboldening).
    func storeTextStyle(_ style: StoreTextStyle) -> some View {
        modifier(StoreTextStyleModifier(style: style))
    }
}

private struct StoreTextStyleModifier: ViewModifier {
    private let style: StoreTextStyle

    // @ScaledMetric scales each value with Dynamic Type relative to .body (uniform scaling
    // across the scale; switch to per-style references if the design needs distinct curves).
    @ScaledMetric private var scaledSize: CGFloat
    @ScaledMetric private var scaledLineSpacing: CGFloat
    @ScaledMetric private var scaledTracking: CGFloat

    init(style: StoreTextStyle) {
        self.style = style
        // Figma line height is the full line box; SwiftUI `.lineSpacing` adds to the font's
        // natural line height, so subtract it. Clamped at 0 — a few styles specify a line
        // height slightly below the system font's natural one, which lineSpacing can't reduce.
        let naturalLineHeight = UIFont.systemFont(ofSize: style.size).lineHeight
        let extraLineSpacing = max(0, style.lineHeight - naturalLineHeight)

        _scaledSize = ScaledMetric(wrappedValue: style.size, relativeTo: .body)
        _scaledLineSpacing = ScaledMetric(wrappedValue: extraLineSpacing, relativeTo: .body)
        _scaledTracking = ScaledMetric(wrappedValue: style.tracking, relativeTo: .body)
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: scaledSize, weight: style.weight))
            .tracking(scaledTracking)
            .lineSpacing(scaledLineSpacing)
    }
}
