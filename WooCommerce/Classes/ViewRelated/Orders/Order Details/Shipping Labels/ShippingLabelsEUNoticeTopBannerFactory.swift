import Foundation

final class ShippingLabelsEUNoticeTopBannerFactory {
    func createTopBanner() -> TopBannerView {
        let learnMoreAction = TopBannerViewModel.ActionButton(title: Localization.learnMore) { _ in
            NSLog("Learn more clicked")
        }

        let dismissAction = TopBannerViewModel.ActionButton(title: Localization.dismiss) { _ in
            NSLog("Dismiss clicked")
        }

        let viewModel = TopBannerViewModel(
                title: nil,
                infoText: Localization.info,
                icon: .infoImage,
                isExpanded: true,
                topButton: .dismiss(handler: {}),
                actionButtons: [learnMoreAction, dismissAction])
        let topBannerView = TopBannerView(viewModel: viewModel)
        topBannerView.translatesAutoresizingMaskIntoConstraints = false
        return topBannerView
    }
}

private extension ShippingLabelsEUNoticeTopBannerFactory {
    enum Localization {
        static let info = NSLocalizedString("When shipping to countries that follow European Union (EU) customs rules, " +
                                            "you must provide a clear, specific description of every item. Otherwise, " +
                                            "shipments may be delayed or interrupted at customs.",
                                            comment: "The EU notice banner content describing why some countries require special customs description")
        static let learnMore = NSLocalizedString("Learn more", comment: "Label for the banner Learn more button")
        static let dismiss = NSLocalizedString("Dismiss", comment: "Label for the banner Dismiss button")
    }
}
