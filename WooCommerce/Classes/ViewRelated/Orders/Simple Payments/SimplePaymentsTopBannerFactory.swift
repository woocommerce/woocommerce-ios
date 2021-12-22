import Yosemite

/// Factory for the SimplePayments top banners
///
struct SimplePaymentsTopBannerFactory {

    /// Creates a banner to be shown when the simple payments has been enabled in the beta features screen
    ///
    static func createFeatureEnabledBanner(onTopButtonPressed: @escaping () -> Void,
                                           onDismissButtonPressed: @escaping () -> Void,
                                           onGiveFeedbackButtonPressed: @escaping () -> Void) -> TopBannerView {
        let dismissAction = TopBannerViewModel.ActionButton(title: Localization.dismiss, action: { _ in onDismissButtonPressed() })
        let giveFeedbackAction = TopBannerViewModel.ActionButton(title: Localization.giveFeedback, action: { _ in onGiveFeedbackButtonPressed() })
        let viewModel = TopBannerViewModel(title: Localization.title,
                                           infoText: Localization.enabledInfo,
                                           icon: .megaphoneIcon,
                                           isExpanded: false,
                                           topButton: .chevron(handler: onTopButtonPressed),
                                           actionButtons: [giveFeedbackAction, dismissAction])
        let topBannerView = TopBannerView(viewModel: viewModel)
        topBannerView.translatesAutoresizingMaskIntoConstraints = false
        return topBannerView
    }
}

private extension SimplePaymentsTopBannerFactory {
    enum Localization {
        static let title = NSLocalizedString("Take payments from your device!", comment: "Title of the banner notice in the Simple Payments feature")
        static let enabledInfo = NSLocalizedString("We are working on making it easier for you to take payments from your device! " +
                                                   "For now, tap on the \"+\" button and you’ll be able to create an order with the amount you want to collect",
                                                   comment: "Content of the banner notice in the Simple Payments view")
        static let dismiss = NSLocalizedString("Dismiss", comment: "The title of the button to dismiss the SimplePayments top banner")
        static let giveFeedback = NSLocalizedString("Give feedback", comment: "Title of the button to give feedback about the Simple Payments feature")
    }
}
