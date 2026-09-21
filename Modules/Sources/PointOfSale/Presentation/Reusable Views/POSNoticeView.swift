import SwiftUI

/// A reusable notice view component that displays information with an icon, title, optional dismiss button, and optional content view.
/// Design refs: 1qcjzXitBHU7xPnpCOWnNM-fi-67_18935, 1qcjzXitBHU7xPnpCOWnNM-fi-67_18939
struct POSNoticeView<Content: View>: View {
    enum Style {
        case neutral
        case alertLowest

        var backgroundColor: Color {
            switch self {
            case .neutral:
                Color.posSurfaceBright
            case .alertLowest:
                Color.posAlertLowest
            }
        }

        var foregroundColor: Color {
            switch self {
            case .neutral:
                Color.posOnSurface
            case .alertLowest:
                Color.posOnAlertLowest
            }
        }

        var dismissIconColor: Color {
            switch self {
            case .neutral:
                Color.posOnSurfaceVariantLowest
            case .alertLowest:
                Color.posOnAlertLowest
            }
        }
    }

    private let title: String
    private let icon: Image
    private let style: Style
    private let onDismiss: (() -> Void)?
    private let onTap: (() -> Void)?
    private let content: Content?

    init(
        title: String,
        icon: Image,
        style: Style = .neutral,
        onDismiss: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content? = { nil }
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.onDismiss = onDismiss
        self.onTap = onTap
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: Constants.padding) {
            VStack {
                Spacer()
                Text(icon.resizable())
                    .font(.posButtonSymbolLarge)
                    .padding(.horizontal, Constants.iconHorizontalPadding)
                    .foregroundColor(style.foregroundColor)
                    .accessibilityHidden(true)
                Spacer()
            }
            VStack(alignment: .leading, spacing: Constants.titleSpacing) {
                Text(title)
                    .font(Constants.titleFont)
                    .accessibilityAddTraits(.isHeader)
                if let content {
                    content
                        .font(Constants.contentFont)
                        .lineSpacing(Constants.textSpacing)
                        .accessibilityElement(children: .combine)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .frame(maxWidth: .infinity, alignment: .leading)

            if let onDismiss {
                VStack {
                    Button(
                        action: onDismiss,
                        label: {
                            Text(Image(systemName: "xmark"))
                                .font(.posButtonSymbolSmall)
                                .foregroundColor(style.dismissIconColor)
                                .accessibilityLabel(Localization.dismissAccessibilityLabel)
                        }
                    )
                    .padding(Constants.dismissIconPadding)
                    Spacer()
                }
            }
        }
        .foregroundColor(style.foregroundColor)
        .padding(Constants.padding)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background(style.backgroundColor)
        .cornerRadius(Constants.cornerRadius)
        .posShadow(.medium, cornerRadius: Constants.cornerRadius)
        .if(onTap != nil) { view in
            view
                .accessibilityAddTraits(.isButton)
                .onTapGesture {
                    onTap?()
                }
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let titleFont: POSFontStyle = .posBodyLargeBold
    static let contentFont: POSFontStyle = .posBodySmallRegular()
    static let cornerRadius: CGFloat = POSCornerRadiusStyle.medium.value
    static let textSpacing: CGFloat = POSSpacing.xSmall
    static let titleSpacing: CGFloat = POSSpacing.small
    static let iconHorizontalPadding: CGFloat = POSPadding.small
    static let dismissIconPadding: CGFloat = 6
    static let padding: CGFloat = POSPadding.medium
}

private enum Localization {
    static let dismissAccessibilityLabel = NSLocalizedString(
        "pos.noticeView.dismiss.button.accessibiltyLabel",
        value: "Dismiss",
        comment: "Accessibility label for button to dismiss a notice banner"
    )
}

#Preview("With all options") {
    POSNoticeView(
        title: "Example Notice",
        icon: Image(systemName: "exclamationmark.triangle"),
        onDismiss: {},
        onTap: {}
    ) {
        VStack(alignment: .leading, spacing: Constants.textSpacing) {
            Text("This is a subtitle that explains more about the notice.")
            Text("Here's a hint about what to do next. Learn More")
                .font(.posBodySmallBold())
                .foregroundColor(Color.posPrimary)
        }
    }
    .padding()
}

#Preview("Without dismiss") {
    POSNoticeView(
        title: "Example Notice",
        icon: Image(systemName: "bell"),
        onTap: {}
    ) {
        VStack(alignment: .leading, spacing: Constants.textSpacing) {
            Text("This is a subtitle that explains more about the notice.")
            Text("Here's a hint about what to do next. Learn More")
                .font(.posBodySmallBold())
                .foregroundColor(Color.posPrimary)
        }
    }
    .padding()
}

#Preview("Banner that fits to width") {
    POSNoticeView<AnyView>(
        title: "Example Notice",
        icon: Image(systemName: "info.circle")
    )
    .fixedSize(horizontal: true, vertical: true)
    .padding()
}
