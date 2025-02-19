import SwiftUI

/// A reusable notice view component that displays information with an icon, title, optional subtitle, optional dismiss button, and optional hint view.
/// Design ref: 1qcjzXitBHU7xPnpCOWnNM-fi-67_18935
struct POSNoticeView<HintContent: View>: View {
    private let title: String
    private let subtitle: String?
    private let icon: Image
    private let onDismiss: (() -> Void)?
    private let onTap: (() -> Void)?
    private let hintContent: HintContent?

    init(
        title: String,
        subtitle: String? = nil,
        icon: Image,
        onDismiss: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder hintContent: () -> HintContent? = { nil }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.onDismiss = onDismiss
        self.onTap = onTap
        self.hintContent = hintContent()
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
                VStack(alignment: .leading, spacing: Constants.textSpacing) {
                    if let subtitle {
                        Text(subtitle)
                    }
                    if let hintContent {
                        hintContent
                    }
                }
                .font(Constants.subtitleFont)
                .lineSpacing(Constants.textSpacing)
                .accessibilityElement(children: .combine)
                .renderedIf(subtitle != nil || hintContent != nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let onDismiss {
                VStack {
                    Button(action: onDismiss, label: {
                        Text(Image(systemName: "xmark"))
                            .font(.posButtonSymbolSmall)
                            .foregroundColor(Color.posOnSurfaceVariantLowest)
                            .accessibilityLabel(Localization.dismissAccessibilityLabel)
                    })
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
        .posShadow(.medium)
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
    static let subtitleFont: POSFontStyle = .posBodySmallRegular()
    static let cornerRadius: CGFloat = POSCornerRadiusStyle.medium.value
    static let textSpacing: CGFloat = 4
    static let titleSpacing: CGFloat = 8
    static let iconHorizontalPadding: CGFloat = 8
    static let dismissIconPadding: CGFloat = 6
    static let padding: CGFloat = 16
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
        subtitle: "This is a subtitle that explains more about the notice.",
        icon: Image(systemName: "exclamationmark.triangle"),
        onDismiss: {},
        onTap: {}
    ) {
        Text("Here's a hint about what to do next. Learn More")
            .font(.posBodySmallBold)
            .foregroundColor(Color(.posPrimary))
    }
    .padding()
}

#Preview("Without dismiss") {
    POSNoticeView(
        title: "Example Notice",
        subtitle: "This is a subtitle that explains more about the notice.",
        icon: Image(systemName: "bell"),
        onTap: {}
    ) {
        Text("Here's a hint about what to do next. Learn More")
            .font(.posBodySmallBold)
            .foregroundColor(Color(.posPrimary))
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
