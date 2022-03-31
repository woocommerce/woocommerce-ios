import Yosemite

/// Factory for the Orders top banners
///
struct OrdersTopBannerFactory {

    /// Creates a banner to be shown on the Orders tab
    ///
    static func createOrdersBanner(onTopButtonPressed: @escaping () -> Void,
                                   onDismissButtonPressed: @escaping () -> Void,
                                   onGiveFeedbackButtonPressed: @escaping () -> Void) -> TopBannerView {
        let dismissAction = TopBannerViewModel.ActionButton(title: Localization.dismiss, action: { _ in onDismissButtonPressed() })
        let giveFeedbackAction = TopBannerViewModel.ActionButton(title: Localization.giveFeedback, action: { _ in onGiveFeedbackButtonPressed() })
        let viewModel = TopBannerViewModel(title: Localization.title,
                                           infoText: Localization.infoText,
                                           icon: .megaphoneIcon,
                                           isExpanded: false,
                                           topButton: .chevron(handler: onTopButtonPressed),
                                           actionButtons: [giveFeedbackAction, dismissAction])
        let topBannerView = TopBannerView(viewModel: viewModel)
        topBannerView.translatesAutoresizingMaskIntoConstraints = false
        return topBannerView
    }
}

private extension OrdersTopBannerFactory {
    enum Localization {
        static let title = NSLocalizedString("Create orders and take payments!", comment: "Title of the banner notice in the Orders tab")
        static let infoText = NSLocalizedString("We've been working on making it possible to create orders and take payments from your device! " +
                                                "You can try these features out by tapping on the \"+\" icon",
                                                comment: "Content of the banner notice in the Orders tab")
        static let dismiss = NSLocalizedString("Dismiss", comment: "The title of the button to dismiss the Orders top banner")
        static let giveFeedback = NSLocalizedString("Give feedback", comment: "Title of the button to give feedback about the Orders features")
    }
}
