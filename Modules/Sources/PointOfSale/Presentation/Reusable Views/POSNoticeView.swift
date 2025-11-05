import SwiftUI

/// A reusable notice view component that displays information with an icon, title, optional dismiss button, and optional content view.
/// Design ref: 1qcjzXitBHU7xPnpCOWnNM-fi-67_18935
struct POSNoticeView<Content: View>: View {
    private let title: String
    private let icon: Image
    private let onDismiss: (() -> Void)?
    private let onTap: (() -> Void)?
    private let content: Content?

    init(
        title: String,
        icon: Image,
        onDismiss: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content? = { nil }
    ) {
        self.title = title
        self.icon = icon
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
                    .foregroundColor(Color.posOnSurface)
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
                                .foregroundColor(Color.posOnSurfaceVariantLowest)
                                .accessibilityLabel(Localization.dismissAccessibilityLabel)
                        }
                    )
                    .padding(Constants.dismissIconPadding)
                    Spacer()
                }
            }
        }
        .padding(Constants.padding)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.posSurfaceBright)
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
