import Yosemite

/// Factory for the QuickPay top banners
///
struct QuickPayTopBannerFactory {

    /// Creates a banner to be shown when the quick pay has not been enabled in the beta features screen
    ///
    static func createFeatureDisabledBanner(onTopButtonPressed: @escaping () -> Void,
                                            onDismissButtonPressed: @escaping () -> Void) -> TopBannerView {
        let dismissAction = TopBannerViewModel.ActionButton(title: Localization.dismiss, action: { _ in onDismissButtonPressed() })
        let viewModel = TopBannerViewModel(title: Localization.title,
                                           infoText: Localization.disabledInfo,
                                           icon: .megaphoneIcon,
                                           isExpanded: false,
                                           topButton: .chevron(handler: onTopButtonPressed),
                                           actionButtons: [dismissAction])
        let topBannerView = TopBannerView(viewModel: viewModel)
        topBannerView.translatesAutoresizingMaskIntoConstraints = false
        return topBannerView
    }

    /// Creates a banner to be shown when the quick pay has been enabled in the beta features screen
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

private extension QuickPayTopBannerFactory {
    enum Localization {
        static let title = NSLocalizedString("Take payments from your device!", comment: "Title of the banner notice in the Quick Pay feature")
        static let disabledInfo = NSLocalizedString("We are working on making it easier for you to take payments from your device! " +
                                                    "Enable Quick Order in Settings > Experimental Features.",
                                                    comment: "Content of the top banner to announce the quick pay feature.")
        static let enabledInfo = NSLocalizedString("We are working on making it easier for you to take payments from your device! " +
                                                   "For now, tap on the \"+\" button and you’ll be able to create an order with the amount you want to collect",
                                                   comment: "Content of the banner notice in the Quick Pay view")
        static let dismiss = NSLocalizedString("Dismiss", comment: "The title of the button to dismiss the QuickPay top banner")
        static let giveFeedback = NSLocalizedString("Give feedback", comment: "Title of the button to give feedback about the Quick Pay feature")
    }
}
