import SwiftUI
import UIKit

public extension View {
    /// Applies a design-system text style (font, weight, line height, tracking) that
    /// scales with Dynamic Type.
    func storeTextStyle(_ style: StoreTextStyle) -> some View {
        modifier(StoreTextStyleModifier(style: style))
    }
}

private struct StoreTextStyleModifier: ViewModifier {
    private let style: StoreTextStyle

    // Tracks the iOS "Bold Text" accessibility setting (.bold when enabled).
    @Environment(\.legibilityWeight) private var legibilityWeight

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
            .font(.system(size: scaledSize, weight: resolvedWeight))
            .tracking(scaledTracking)
            .lineSpacing(scaledLineSpacing)
    }

    /// When the user enables Bold Text (Settings → Accessibility → Bold Text), the design
    /// shifts weights up: Medium → Semibold, Bold → Heavy (Regular stays Regular). Mirrors
    /// the "iOS Extra bold" mode of the Figma Font theme. `Font.Weight` is a struct, not an
    /// enum, so this compares with `==` rather than switching over cases.
    private var resolvedWeight: Font.Weight {
        guard legibilityWeight == .bold else { return style.weight }
        if style.weight == .medium { return .semibold }
        if style.weight == .bold { return .heavy }
        return style.weight
    }
}
