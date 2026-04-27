import SwiftUI

/// iOS type style definitions for POS
/// 1qcjzXitBHU7xPnpCOWnNM-fi-23_7310
enum POSFontStyle {
    case posHeadingBold
    case posHeadingRegular
    case posBodyXLargeRegular
    case posBodyXLargeBold
    case posBodyLargeBold
    case posBodyLargeRegular(underline: Bool = false)
    case posBodyMediumBold
    case posBodyMediumRegular(underline: Bool = false)
    case posBodySmallBold(underline: Bool = false)
    case posBodySmallRegular(underline: Bool = false)
    case posCaptionBold
    case posCaptionRegular
    case posButtonSymbolXSmall
    case posButtonSymbolSmall
    case posButtonSymbolMedium
    case posButtonSymbolLarge

    func font(maximumContentSizeCategory: UIContentSizeCategory? = nil) -> Font {
        switch self {
        case .posHeadingBold:
            Font.system(size: scaledValue(FontSize.heading, maximumContentSizeCategory: maximumContentSizeCategory ?? .accessibilityLarge), weight: .bold)
        case .posHeadingRegular:
            Font.system(size: scaledValue(FontSize.heading, maximumContentSizeCategory: maximumContentSizeCategory ?? .accessibilityLarge), weight: .regular)
        case .posBodyXLargeRegular:
            Font.system(
                size: scaledValue(FontSize.bodyXLarge, maximumContentSizeCategory: maximumContentSizeCategory ?? .accessibilityLarge),
                weight: .semibold
            )
        case .posBodyXLargeBold:
            Font.system(
                size: scaledValue(FontSize.bodyXLarge, maximumContentSizeCategory: maximumContentSizeCategory ?? .accessibilityLarge),
                weight: .bold
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
        case .posButtonSymbolXSmall:
            Font.system(size: scaledValue(16, maximumContentSizeCategory: maximumContentSizeCategory), weight: .semibold)
        case .posButtonSymbolSmall:
            Font.system(size: scaledValue(20, maximumContentSizeCategory: maximumContentSizeCategory), weight: .semibold)
        case .posButtonSymbolMedium:
            Font.system(size: scaledValue(24, maximumContentSizeCategory: maximumContentSizeCategory), weight: .semibold)
        case .posButtonSymbolLarge:
            Font.system(size: scaledValue(30, maximumContentSizeCategory: maximumContentSizeCategory), weight: .semibold)
        }
    }

    private func scaledValue(_ value: CGFloat, maximumContentSizeCategory: UIContentSizeCategory?) -> CGFloat {
        let metrics = UIFontMetrics.default
        let scaledValue = metrics.scaledValue(for: value)
        guard let maximumContentSizeCategory else {
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

    func body(content: Content) -> some View {
        let category = UIContentSizeCategory(dynamicTypeSize)

        return content
            .font(style.font(maximumContentSizeCategory: category))
            .if(shouldUnderline()) { view in
                view.underline()
            }
    }

    private func shouldUnderline() -> Bool {
        switch style {
        case .posBodyLargeRegular(let underline),
                .posBodyMediumRegular(let underline),
                .posBodySmallRegular(let underline),
                .posBodySmallBold(let underline):
            return underline
        default:
            return false
        }
    }
}

extension View {
    func font(_ style: POSFontStyle) -> some View {
        return self.modifier(POSScaledFont(style: style))
    }
}

// Helper to convert DynamicTypeSize to UIContentSizeCategory
extension UIContentSizeCategory {
    init(_ dynamicTypeSize: DynamicTypeSize) {
        switch dynamicTypeSize {
        case .xSmall: self = .extraSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .xLarge: self = .extraLarge
        case .xxLarge: self = .extraExtraLarge
        case .xxxLarge: self = .extraExtraExtraLarge
        case .accessibility1: self = .accessibilityMedium
        case .accessibility2: self = .accessibilityLarge
        case .accessibility3: self = .accessibilityExtraLarge
        case .accessibility4: self = .accessibilityExtraExtraLarge
        case .accessibility5: self = .accessibilityExtraExtraExtraLarge
        @unknown default: self = .large
        }
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                Text("Heading Bold")
                    .font(.posHeadingBold)
                Text("Heading Regular")
                    .font(.posHeadingRegular)
                Text("Body Extra Large Regular")
                    .font(.posBodyXLargeRegular)
                Text("Body Extra Large Bold")
                    .font(.posBodyXLargeBold)
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
                    .font(.posBodySmallBold())
                Text("Body Small Bold Underline")
                    .font(.posBodySmallBold(underline: true))
                Text("Body Small Regular")
                    .font(.posBodySmallRegular())
                Text("Body Small Regular Underline")
                    .font(.posBodySmallRegular(underline: true))
                Text("Caption Bold")
                    .font(.posCaptionBold)
                Text("Caption Regular")
                    .font(.posCaptionRegular)
                Text("Button Symbol XSmall")
                    .font(.posButtonSymbolXSmall)
                Text("Button Symbol Small")
                    .font(.posButtonSymbolSmall)
                Text("Button Symbol Medium")
                    .font(.posButtonSymbolMedium)
                Text("Button Symbol Large")
                    .font(.posButtonSymbolLarge)
            }
        }
        .padding()
    }
}
#endif
