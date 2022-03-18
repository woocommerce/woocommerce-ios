import SwiftUI

/// View to enable WC Analytics for the current store
///
struct EnableAnalyticsView: View {
    @ObservedObject private var viewModel: EnableAnalyticsViewModel
    @Environment(\.presentationMode) private var presentation

    private let contactSupportAction: () -> Void
    private let completionHandler: () -> Void
    private let noticePresenter: DefaultNoticePresenter

    /// Keeping a reference to the presenting controller to present notice and contact support
    private let presentingController: UIViewController?

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
         presentingController: UIViewController?,
         completionHandler: @escaping () -> Void) {
        self.viewModel = viewModel
        self.completionHandler = completionHandler

        self.contactSupportAction = {
            if let viewController = presentingController?.presentedViewController {
                ZendeskProvider.shared.showNewRequestIfPossible(from: viewController)
            }
        }

        self.noticePresenter = DefaultNoticePresenter()
        self.presentingController = presentingController
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
            Button(Localization.enableAction) {
                viewModel.enableAnalytics(onSuccess: {
                    setupNoticePresenterIfPossible()
                    let notice = Notice(title: Localization.analyticsEnabled, feedbackType: .success)
                    noticePresenter.enqueue(notice: notice)
                    completionHandler()
                    presentation.wrappedValue.dismiss()
                }, onFailure: {
                    setupNoticePresenterIfPossible()
                    let notice = Notice(title: Localization.errorEnablingAnalytics, feedbackType: .error)
                    noticePresenter.enqueue(notice: notice)
                })
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.enablingAnalyticsInProgress))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Constants.actionButtonMargin)
            .padding(.bottom, Constants.actionButtonMargin)

            Button(Localization.dismissAction) {
                presentation.wrappedValue.dismiss()
            }
            .buttonStyle(SecondaryButtonStyle())
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Constants.actionButtonMargin)
            .padding(.bottom, Constants.actionButtonMargin)
        }
    }

    private func setupNoticePresenterIfPossible() {
        guard let currentModal = presentingController?.presentedViewController,
              noticePresenter.presentingViewController == nil else {
            return
        }
        noticePresenter.presentingViewController = currentModal
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
        static let analyticsEnabled = NSLocalizedString("Analytics enabled successfully.", comment: "Message when enabling analytics succeeds")
        static let errorEnablingAnalytics = NSLocalizedString(
            "Error enabling analytics. Please try again.",
            comment: "Error message when enabling analytics fails"
        )
    }
}

struct EnableAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        EnableAnalyticsView(viewModel: .init(siteID: 123),
                            presentingController: nil,
                            completionHandler: {})
    }
}
