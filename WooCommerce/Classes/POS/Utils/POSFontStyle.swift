import SwiftUI

/// iOS type style definitions for POS
/// TfaZ4LUkEwEGrxfnEFzvJj-fi-3385_18076
enum POSFontStyle {
    case posTitleRegular
    case posTitleEmphasized
    case posBodyRegular
    case posBodyEmphasized
    case posDetailLight
    case posDetailRegular
    case posDetailEmphasized

    var font: Font {
        switch self {
        case .posTitleRegular:
            Font.system(size: UIFontMetrics.default.scaledValue(for: 36), weight: .medium)
        case .posTitleEmphasized:
            Font.system(size: UIFontMetrics.default.scaledValue(for: 36), weight: .bold)
        case .posBodyRegular:
            Font.system(size: UIFontMetrics.default.scaledValue(for: 24), weight: .regular)
        case .posBodyEmphasized:
            Font.system(size: UIFontMetrics.default.scaledValue(for: 24), weight: .bold)
        case .posDetailLight:
            Font.system(size: UIFontMetrics.default.scaledValue(for: 16), weight: .regular)
        case .posDetailRegular:
            Font.system(size: UIFontMetrics.default.scaledValue(for: 16), weight: .medium)
        case .posDetailEmphasized:
            Font.system(size: UIFontMetrics.default.scaledValue(for: 16), weight: .semibold)
        }
    }
}

// MARK: - Helpers

private struct POSScaledFont: ViewModifier {
    // Declaring sizeCategory ensures it's automatically observed
    @Environment(\.sizeCategory) var sizeCategory
    var style: POSFontStyle

    func body(content: Content) -> some View {
        return content.font(style.font)
    }
}

extension View {
    func font(_ style: POSFontStyle) -> some View {
        return self.modifier(POSScaledFont(style: style))
    }
}
