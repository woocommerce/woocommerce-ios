import SwiftUI

/// A reusable notice view component that displays information with an icon, title, subtitle, optional dismiss button, and optional hint view.
/// Design ref: 1qcjzXitBHU7xPnpCOWnNM-fi-67_18935
struct POSNoticeView<HintContent: View>: View {
    let title: String
    let subtitle: String
    let onDismiss: (() -> Void)?
    let onTap: (() -> Void)?
    let hintContent: HintContent?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        title: String,
        subtitle: String,
        onDismiss: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder hintContent: () -> HintContent? = { nil }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onDismiss = onDismiss
        self.onTap = onTap
        self.hintContent = hintContent()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack {
                Spacer()
                Text(Image(systemName: "info.circle"))
                    .font(.posButtonSymbolLarge)
                    .padding(Constants.iconPadding)
                    .foregroundColor(Color.posOnSurface)
                    .accessibilityHidden(true)
                Spacer()
            }
            VStack(alignment: .leading, spacing: Constants.titleSpacing) {
                Text(title)
                    .font(Constants.titleFont)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: Constants.textSpacing) {
                    Text(subtitle)
                    if let hintContent {
                        hintContent
                    }
                }
                .font(Constants.subtitleFont)
                .lineSpacing(Constants.textSpacing)
                .accessibilityElement(children: .combine)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Constants.verticalPadding)

            if let onDismiss {
                VStack {
                    Button(action: onDismiss, label: {
                        Text(Image(systemName: "xmark"))
                            .font(.posButtonSymbolSmall)
                            .foregroundColor(Color.posOnSurfaceVariantLowest)
                            .accessibilityLabel(Localization.dismissAccessibilityLabel)
                    })
                    .padding(Constants.iconPadding)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.posSurfaceBright)
        .cornerRadius(Constants.cornerRadius)
        .posShadow(.medium)
        .if(onTap != nil) { view in
            view.accessibilityAddTraits(.isButton)
        }
        .if(onTap != nil) { view in
            view.onTapGesture {
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
    static let verticalPadding: CGFloat = 26
    static let textSpacing: CGFloat = 4
    static let titleSpacing: CGFloat = 8
    static let iconPadding: CGFloat = 26
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
        onTap: {}
    ) {
        Text("Here's a hint about what to do next. Learn More")
            .font(.posBodySmallBold)
            .foregroundColor(Color(.posPrimary))
    }
    .padding()
}

#Preview("Basic") {
    POSNoticeView<AnyView>(
        title: "Example Notice",
        subtitle: "This is a subtitle that explains more about the notice."
    )
    .padding()
}
