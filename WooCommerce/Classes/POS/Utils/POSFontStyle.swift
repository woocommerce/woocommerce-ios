import SwiftUI

/// iOS type style definitions for POS
/// 1qcjzXitBHU7xPnpCOWnNM-fi-23_7310
enum POSFontStyle {
    case posHeading
    case posBodyXLarge
    case posBodyLargeBold
    case posBodyLargeRegular(underline: Bool = false)
    case posBodyMediumBold
    case posBodyMediumRegular(underline: Bool = false)
    case posBodySmallBold
    case posBodySmallRegular(underline: Bool = false)
    case posCaptionBold
    case posCaptionRegular
    case posButtonSymbol
    
    func font(maximumContentSizeCategory: UIContentSizeCategory? = nil) -> Font {
        switch self {
        case .posHeading:
            Font.system(size: scaledValue(FontSize.heading, maximumContentSizeCategory: maximumContentSizeCategory ?? .accessibilityLarge), weight: .bold)
        case .posBodyXLarge:
            Font.system(
                size: scaledValue(FontSize.bodyXLarge, maximumContentSizeCategory: maximumContentSizeCategory ?? .accessibilityLarge),
                weight: .semibold
            )
        case .posBodyLargeBold:
            Font.system(size: scaledValue(FontSize.bodyLarge, maximumContentSizeCategory: maximumContentSizeCategory), weight: .bold)
        case .posBodyLargeRegular:
            Font.system(size: scaledValue(FontSize.bodyLarge, maximumContentSizeCategory: maximumContentSizeCategory), weight: .regular)
        case .posBodyMediumBold:
            Font.system(size: scaledValue(FontSize.bodyMedium, maximumContentSizeCategory: maximumContentSizeCategory), weight: .bold)
        case .posBodyMediumRegular:
            Font.system(size: scaledValue(FontSize.bodyMedium, maximumContentSizeCategory: maximumContentSizeCategory), weight: .regular)
        case .posBodySmallBold:
            Font.system(size: scaledValue(FontSize.bodySmall, maximumContentSizeCategory: maximumContentSizeCategory), weight: .bold)
        case .posBodySmallRegular:
            Font.system(size: scaledValue(FontSize.bodySmall, maximumContentSizeCategory: maximumContentSizeCategory), weight: .regular)
        case .posCaptionBold:
            Font.system(size: scaledValue(FontSize.caption, maximumContentSizeCategory: maximumContentSizeCategory), weight: .bold)
        case .posCaptionRegular:
            Font.system(size: scaledValue(FontSize.caption, maximumContentSizeCategory: maximumContentSizeCategory), weight: .regular)
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
        content
            .font(style.font(maximumContentSizeCategory: maximumContentSizeCategory))
            .if(shouldUnderline()) { view in
                view.underline()
            }
    }
    
    private func shouldUnderline() -> Bool {
        switch style {
        case .posBodyLargeRegular(let underline),
                .posBodyMediumRegular(let underline),
                .posBodySmallRegular(let underline):
            return underline
        default:
            return false
        }
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
                Text("Title Emphasized")
                    .font(.posHeading)
                Text("Body Extra Large")
                    .font(.posBodyXLarge)
                Text("Body Large Bold")
                    .font(.posBodyLargeBold)
                Text("Body Large Regular")
                    .font(.posBodyLargeRegular())
                Text("Body Large Regular Underline")
                    .font(.posBodyLargeRegular(underline: true))
                Text("Body Medium Bold")
                    .font(.posBodyMediumBold)
                Text("Body Medium Regular")
                    .font(.posBodyMediumRegular())
                Text("Body Medium Regular Underline")
                    .font(.posBodyMediumRegular(underline: true))
                Text("Body Small Bold")
                    .font(.posBodySmallBold)
                Text("Body Small Regular")
                    .font(.posBodySmallRegular())
                Text("Body Small Regular Underline")
                    .font(.posBodySmallRegular(underline: true))
                Text("Caption Bold")
                    .font(.posCaptionBold)
                Text("Caption Regular")
                    .font(.posCaptionRegular)
                Text("Button Symbol")
                    .font(.posButtonSymbol)
            }
        }
        .padding()
    }
}
