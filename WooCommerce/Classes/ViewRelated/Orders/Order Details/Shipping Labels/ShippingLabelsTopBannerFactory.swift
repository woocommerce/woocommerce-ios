import Yosemite

/// Creates a top banner for shipping labels asynchronously based on the shipping labels and app settings.
/// The top banner has two actions: "give feedback" and "dismiss".
/// This class is not meant to be retained since it uses strong `self` in action handling, so that it has the same life cycle as the top banner.
final class ShippingLabelsTopBannerFactory {
    private var shouldShowShippingLabelCreation: Bool
    private let shippingLabels: [ShippingLabel]
    private let stores: StoresManager
    private let analytics: Analytics

    init(shouldShowShippingLabelCreation: Bool,
         shippingLabels: [ShippingLabel],
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.shouldShowShippingLabelCreation = shouldShowShippingLabelCreation
        self.shippingLabels = shippingLabels
        self.stores = stores
        self.analytics = analytics
    }

    /// Creates a top banner asynchronously based on the shipping labels and app settings.
    /// - Parameters:
    ///   - isExpanded: whether the top banner is expanded by default.
    ///   - expandedStateChangeHandler: called when the top banner expanded state changes.
    ///   - onGiveFeedbackButtonPressed: called when the give feedback button is pressed.
    ///   - onDismissButtonPressed: called when the dismiss button is pressed.
    ///   - onCompletion: called when it finishes determining whether the top banner is being shown, and an optional top banner is returned.
    func createTopBannerIfNeeded(isExpanded: Bool,
                                 expandedStateChangeHandler: @escaping () -> Void,
                                 onGiveFeedbackButtonPressed: @escaping () -> Void,
                                 onDismissButtonPressed: @escaping () -> Void,
                                 onCompletion: @escaping (TopBannerView?) -> Void) {
        determineIfTopBannerShouldBeShown { [weak self] shouldShow in
            guard let self = self else { return }

            guard shouldShow else {
                onCompletion(nil)
                return
            }

            onCompletion(self.createTopBanner(isExpanded: isExpanded,
                                              expandedStateChangeHandler: expandedStateChangeHandler,
                                              onGiveFeedbackButtonPressed: onGiveFeedbackButtonPressed,
                                              onDismissButtonPressed: onDismissButtonPressed))
        }
    }
}

private extension ShippingLabelsTopBannerFactory {
    func determineIfTopBannerShouldBeShown(onCompletion: @escaping (_ shouldShow: Bool) -> Void) {
        guard shouldShowShippingLabelCreation && shippingLabels.nonRefunded.isEmpty else {
            onCompletion(false)
            return
        }

        let action = AppSettingsAction.loadFeedbackVisibility(type: .shippingLabelsRelease3) { result in
            switch result {
            case .success(let visible):
                onCompletion(visible)
            case.failure:
                onCompletion(false)
            }
        }
        stores.dispatch(action)
    }

    func createTopBanner(isExpanded: Bool,
                         expandedStateChangeHandler: @escaping () -> Void,
                         onGiveFeedbackButtonPressed: @escaping () -> Void,
                         onDismissButtonPressed: @escaping () -> Void) -> TopBannerView {
        let title = Localization.title
        let icon: UIImage = .megaphoneIcon
        let infoText = Localization.info
        let giveFeedbackAction = TopBannerViewModel.ActionButton(title: Localization.giveFeedback) { _ in
            self.analytics.track(event: .featureFeedbackBanner(context: .shippingLabelsRelease3, action: .gaveFeedback))
            onGiveFeedbackButtonPressed()
        }
        let dismissAction = TopBannerViewModel.ActionButton(title: Localization.dismiss) { _ in
            self.analytics.track(event: .featureFeedbackBanner(context: .shippingLabelsRelease3, action: .dismissed))
            let action = AppSettingsAction.updateFeedbackStatus(type: .shippingLabelsRelease3, status: .dismissed) { result in
                onDismissButtonPressed()
            }
            self.stores.dispatch(action)
        }
        let actions = [giveFeedbackAction, dismissAction]
        let viewModel = TopBannerViewModel(title: title,
                                           infoText: infoText,
                                           icon: icon,
                                           isExpanded: isExpanded,
                                           topButton: .chevron(handler: expandedStateChangeHandler),
                                           actionButtons: actions)
        let topBannerView = TopBannerView(viewModel: viewModel)
        topBannerView.translatesAutoresizingMaskIntoConstraints = false

        return topBannerView
    }
}

private extension ShippingLabelsTopBannerFactory {
    enum Localization {
        static let title =
            NSLocalizedString("Create shipping labels from your device!",
                              comment: "The title of the shipping labels top banner in order details")
        static let info =
            NSLocalizedString(
                "You can now create shipping labels for all physical orders directly from your device with the free WooCommerce Shipping plugin. "
                    + "Tap on Create Shipping Label to try our beta feature!",
                comment: "The info of the shipping labels top banner in order details")
        static let giveFeedback =
            NSLocalizedString("Give feedback",
                              comment: "The title of the button to give feedback about shipping labels features on the banner in order details")
        static let dismiss = NSLocalizedString("Dismiss", comment: "The title of the button to dismiss the banner in order details")
    }
}
