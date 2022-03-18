import SwiftUI

/// View to enable WC Analytics for the current store
///
struct EnableAnalyticsView: View {
    @ObservedObject private var viewModel: EnableAnalyticsViewModel

    private let contactSupportAction: () -> Void
    private let dismissAction: () -> Void

    private var contactSupportAttributedString: NSAttributedString {
        let font: UIFont = .body
        let foregroundColor: UIColor = .text
        let linkColor: UIColor = .textLink
        let linkContent = Localization.contactSupport

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributedString = NSMutableAttributedString(
            string: String(format: "%@ %@", Localization.needSomeHelp, linkContent),
            attributes: [.font: font,
                         .foregroundColor: foregroundColor,
                         .paragraphStyle: paragraphStyle,
                        ]
        )
        let contactSupportLink = NSAttributedString(string: linkContent, attributes: [.font: font, .foregroundColor: linkColor])
        attributedString.replaceFirstOccurrence(of: linkContent, with: contactSupportLink)
        return attributedString
    }

    init(viewModel: EnableAnalyticsViewModel,
         contactSupportAction: @escaping () -> Void,
         dismissAction: @escaping () -> Void) {
        self.viewModel = viewModel
        self.contactSupportAction = contactSupportAction
        self.dismissAction = dismissAction
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: Constants.contentSpacing) {
                Text(Localization.title)
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)

                Image(uiImage: .enableAnalyticsImage)
                    .padding(Constants.imagePadding)

                Text(Localization.analyticsDisabled)
                    .bodyStyle()

                Text(Localization.analyticsExplained)
                    .bodyStyle()

                Button(action: contactSupportAction, label: {
                    AttributedText(contactSupportAttributedString)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentShape(Rectangle())
                }).buttonStyle(.plain)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Constants.contentHorizontalMargin)
            .scrollVerticallyIfNeeded()

            Spacer()

            // Primary Button to enable Analytics
            Button(Localization.enableAction, action: {
                // TODO
            })
            .buttonStyle(PrimaryButtonStyle())
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Constants.actionButtonMargin)
            .padding(.bottom, Constants.actionButtonMargin)

            Button(Localization.dismissAction, action: dismissAction)
                .buttonStyle(SecondaryButtonStyle())
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Constants.actionButtonMargin)
                .padding(.bottom, Constants.actionButtonMargin)
        }
    }
}

private extension EnableAnalyticsView {
    enum Constants {
        static let actionButtonMargin: CGFloat = 16
        static let contentHorizontalMargin: CGFloat = 40
        static let contentSpacing: CGFloat = 16
        static let imagePadding: CGFloat = 32
    }

    enum Localization {
        static let title = NSLocalizedString("Enable WooCommerce Analytics to see your stats", comment: "Title for the enable analytics screen")
        static let analyticsDisabled = NSLocalizedString(
            "It looks like you have analytics disabled.",
            comment: "Message on enable analytics screen to notify that the module is disabled for the store"
        )
        static let analyticsExplained = NSLocalizedString(
            "Enable WooCommerce Analytics to see missing stats for your store.",
            comment: "Description about WooCommerce Analytics on the enable analytics screen"
        )
        static let needSomeHelp = NSLocalizedString("Need some help?", comment: "Message on enable analytics screen for support")
        static let contactSupport = NSLocalizedString("Contact support", comment: "Action button to contact support on enable analytics screen")
        static let enableAction = NSLocalizedString("Enable analytics", comment: "Action title to enable Analytics for a store")
        static let dismissAction = NSLocalizedString("Not now", comment: "Action title to dismiss enabling Analytics for a store")
    }
}

struct EnableAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        EnableAnalyticsView(viewModel: .init(siteID: 123),
                            contactSupportAction: {},
                            dismissAction: {})
    }
}
