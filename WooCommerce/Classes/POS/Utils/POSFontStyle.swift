import SwiftUI

/// iOS type style definitions for POS
/// TfaZ4LUkEwEGrxfnEFzvJj-fi-3385_18076
enum POSFontStyle {
    case posTitleRegular
    case posTitleEmphasized
    case posBodyLargeRegular
    case posBodyLargeEmphasized
    case posBodyMediumEmphasized
    case posBodyMediumRegular
    case posBodySmallLight
    case posBodySmallRegular
    case posBodySmallEmphasized
    case posButtonSymbol

    func font(maximumContentSizeCategory: UIContentSizeCategory? = nil) -> Font {
        switch self {
        case .posTitleRegular:
            Font.system(size: scaledValue(FontSize.heading, maximumContentSizeCategory: maximumContentSizeCategory ?? .accessibilityLarge), weight: .medium)
        case .posTitleEmphasized:
            Font.system(size: scaledValue(FontSize.heading, maximumContentSizeCategory: maximumContentSizeCategory ?? .accessibilityLarge), weight: .bold)
        case .posBodyLargeRegular:
            Font.system(size: scaledValue(FontSize.bodyLarge, maximumContentSizeCategory: maximumContentSizeCategory), weight: .regular)
        case .posBodyLargeEmphasized:
            Font.system(size: scaledValue(FontSize.bodyLarge, maximumContentSizeCategory: maximumContentSizeCategory), weight: .bold)
        case .posBodyMediumEmphasized:
            Font.system(size: scaledValue(FontSize.bodyMedium, maximumContentSizeCategory: maximumContentSizeCategory), weight: .semibold)
        case .posBodyMediumRegular:
            Font.system(size: scaledValue(FontSize.bodyMedium, maximumContentSizeCategory: maximumContentSizeCategory), weight: .regular)
        case .posBodySmallLight:
            Font.system(size: scaledValue(FontSize.bodySmall, maximumContentSizeCategory: maximumContentSizeCategory), weight: .regular)
        case .posBodySmallRegular:
            Font.system(size: scaledValue(FontSize.bodySmall, maximumContentSizeCategory: maximumContentSizeCategory), weight: .medium)
        case .posBodySmallEmphasized:
            Font.system(size: scaledValue(FontSize.bodySmall, maximumContentSizeCategory: maximumContentSizeCategory), weight: .semibold)
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

private extension POSFontStyle {
    enum FontSize {
        static let heading: CGFloat = 36
        static let bodyXLarge: CGFloat = 30
        static let bodyLarge: CGFloat = 24
        static let bodyMedium: CGFloat = 20
        static let bodySmall: CGFloat = 16
        static let caption: CGFloat = 14
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

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                Text("Title Regular")
                    .font(.posTitleRegular)
                Text("Title Emphasized")
                    .font(.posTitleEmphasized)
                Text("Body Large Regular")
                    .font(.posBodyLargeRegular)
                Text("Body Large Emphasized")
                    .font(.posBodyLargeEmphasized)
                Text("Body Medium Regular")
                    .font(.posBodyMediumRegular)
                Text("Body Medium Emphasized")
                    .font(.posBodyMediumEmphasized)
                Text("Body Small Light")
                    .font(.posBodySmallLight)
                Text("Body Small Regular")
                    .font(.posBodySmallRegular)
                Text("Body Small Emphasized")
                    .font(.posBodySmallEmphasized)
                Text("Button Symbol")
                    .font(.posButtonSymbol)
            }
        }
        .padding()
    }
}
