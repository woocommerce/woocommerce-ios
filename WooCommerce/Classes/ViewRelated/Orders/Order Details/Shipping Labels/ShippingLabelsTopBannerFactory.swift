import Yosemite

/// Creates a top banner for shipping labels asynchronously based on the shipping labels and app settings.
/// The top banner has two actions: "give feedback" and "dismiss".
/// This class is not meant to be retained since it uses strong `self` in action handling, so that it has the same life cycle as the top banner.
final class ShippingLabelsTopBannerFactory {
    private let shippingLabels: [ShippingLabel]
    private let stores: StoresManager
    private let analytics: Analytics

    init(shippingLabels: [ShippingLabel],
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.shippingLabels = shippingLabels
        self.stores = stores
        self.analytics = analytics
    }

    /// Creates a top banner asynchronously based on the shipping labels and app settings.
    /// - Parameters:
    ///   - expandable: whether the top banner is expanded by default.
    ///   - expandedStateChangeHandler: called when the top banner expanded state changes.
    ///   - onGiveFeedbackButtonPressed: called when the give feedback button is pressed.
    ///   - onDismissButtonPressed: called when the dismiss button is pressed.
    ///   - onCompletion: called when it finishes determining whether the top banner is being shown, and an optional top banner is returned.
    func createTopBannerIfNeeded(expandable: Bool,
                                 expandedStateChangeHandler: @escaping () -> Void,
                                 onGiveFeedbackButtonPressed: @escaping () -> Void,
                                 onDismissButtonPressed: @escaping () -> Void,
                                 onCompletion: @escaping (TopBannerSwifty?) -> Void) {
        determineIfTopBannerShouldBeShown { [weak self] shouldShow in
            guard let self = self else { return }

            guard shouldShow else {
                onCompletion(nil)
                return
            }

            onCompletion(self.createTopBanner(expandable: expandable,
                                              expandedStateChangeHandler: expandedStateChangeHandler,
                                              onGiveFeedbackButtonPressed: onGiveFeedbackButtonPressed,
                                              onDismissButtonPressed: onDismissButtonPressed))
        }
    }
}

private extension ShippingLabelsTopBannerFactory {
    func determineIfTopBannerShouldBeShown(onCompletion: @escaping (_ shouldShow: Bool) -> Void) {
        guard shippingLabels.nonRefunded.isNotEmpty else {
            onCompletion(false)
            return
        }

        let action = AppSettingsAction.loadFeedbackVisibility(type: .shippingLabelsRelease1) { result in
            switch result {
            case .success(let visible):
                onCompletion(visible)
            case.failure:
                onCompletion(false)
            }
        }
        stores.dispatch(action)
    }

    func createTopBanner(expandable: Bool,
                         expandedStateChangeHandler: @escaping () -> Void,
                         onGiveFeedbackButtonPressed: @escaping () -> Void,
                         onDismissButtonPressed: @escaping () -> Void) -> TopBannerSwifty {
        let title = Localization.title
        let icon: UIImage = .megaphoneIcon
        let infoText = Localization.info
        let giveFeedbackAction = TopBannerSwiftyViewModel.ActionButton(title: Localization.giveFeedback) {
            self.analytics.track(event: .featureFeedbackBanner(context: .shippingLabelsRelease1, action: .gaveFeedback))
            onGiveFeedbackButtonPressed()
        }
        let dismissAction = TopBannerSwiftyViewModel.ActionButton(title: Localization.dismiss) {
            self.analytics.track(event: .featureFeedbackBanner(context: .shippingLabelsRelease1, action: .dismissed))
            let action = AppSettingsAction.updateFeedbackStatus(type: .shippingLabelsRelease1, status: .dismissed) { result in
                onDismissButtonPressed()
            }
            self.stores.dispatch(action)
        }
        let actions = [giveFeedbackAction, dismissAction]
        let viewModel = TopBannerSwiftyViewModel(title: title,
                                           infoText: infoText,
                                           icon: icon,
                                           expandable: expandable,
                                           topButton: .chevron(handler: expandedStateChangeHandler),
                                           actionButtons: actions,
                                           type: .warning)
        let topBannerView = TopBannerSwifty(viewModel: viewModel)

        return topBannerView
    }
}

private extension ShippingLabelsTopBannerFactory {
    enum Localization {
        static let title =
            NSLocalizedString("Print shipping labels from your device!",
                              comment: "The title of the shipping labels top banner in order details")
        static let info =
            NSLocalizedString(
                "We are working on making it easier for you to print shipping labels directly from your device! "
                    + "For now, if you have created labels for an order in your store admin with WooCommerce Shipping, "
                    + "you can print them in your Order details here.",
                comment: "The info of the shipping labels top banner in order details")
        static let giveFeedback =
            NSLocalizedString("Give feedback",
                              comment: "The title of the button to give feedback about shipping labels features on the banner in order details")
        static let dismiss = NSLocalizedString("Dismiss", comment: "The title of the button to dismiss the banner in order details")
    }
}
