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
    case posButtonSymbol

    func font(maximumContentSizeCategory: UIContentSizeCategory? = nil) -> Font {
        switch self {
        case .posTitleRegular:
            Font.system(size: scaledValue(36, maximumContentSizeCategory: maximumContentSizeCategory ?? .accessibilityLarge), weight: .medium)
        case .posTitleEmphasized:
            Font.system(size: scaledValue(36, maximumContentSizeCategory: maximumContentSizeCategory ?? .accessibilityLarge), weight: .bold)
        case .posBodyRegular:
            Font.system(size: scaledValue(24, maximumContentSizeCategory: maximumContentSizeCategory), weight: .regular)
        case .posBodyEmphasized:
            Font.system(size: scaledValue(24, maximumContentSizeCategory: maximumContentSizeCategory), weight: .bold)
        case .posDetailLight:
            Font.system(size: scaledValue(16, maximumContentSizeCategory: maximumContentSizeCategory), weight: .regular)
        case .posDetailRegular:
            Font.system(size: scaledValue(16, maximumContentSizeCategory: maximumContentSizeCategory), weight: .medium)
        case .posDetailEmphasized:
            Font.system(size: scaledValue(16, maximumContentSizeCategory: maximumContentSizeCategory), weight: .semibold)
        case .posButtonSymbol:
            Font.system(size: scaledValue(32, maximumContentSizeCategory: maximumContentSizeCategory), weight: .medium)
        }
    }

    private func scaledValue(_ value: CGFloat, maximumContentSizeCategory: UIContentSizeCategory?) -> CGFloat {
        let metrics = UIFontMetrics.default
        let scaledValue = metrics.scaledValue(for: value)
        guard let maximumContentSizeCategory = maximumContentSizeCategory else {
            return scaledValue
        }

        let maximumScaledValue = metrics.scaledValue(for: value, compatibleWith: .init(preferredContentSizeCategory: maximumContentSizeCategory))

        return min(scaledValue, maximumScaledValue)
    }
}

// MARK: - Helpers

private struct POSScaledFont: ViewModifier {
    // Declaring dynamicTypeSize ensures it's automatically observed
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    var style: POSFontStyle
    var maximumContentSizeCategory: UIContentSizeCategory? = nil

    func body(content: Content) -> some View {
        return content.font(style.font(maximumContentSizeCategory: maximumContentSizeCategory))
    }
}

extension View {
    func font(_ style: POSFontStyle, maximumContentSizeCategory: UIContentSizeCategory? = nil) -> some View {
        return self.modifier(POSScaledFont(style: style, maximumContentSizeCategory: maximumContentSizeCategory))
    }
}
