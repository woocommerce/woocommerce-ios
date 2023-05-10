import Foundation

final class EUShippingNoticeTopBannerFactory {
    static func createTopBanner(onDismissPressed: @escaping () -> Void,
                                onLearnMorePressed: @escaping (URL?) -> Void) -> TopBannerView {
        let learnMoreAction = TopBannerViewModel.ActionButton(title: Localization.learnMore) { _ in
            onLearnMorePressed(URL(string: String.shippingCustomsInstructionsForEUCountries))
        }

        let dismissAction = TopBannerViewModel.ActionButton(title: Localization.dismiss) { _ in
            onDismissPressed()
        }

        let viewModel = TopBannerViewModel(title: nil,
                                           infoText: Localization.info,
                                           icon: .infoOutlineImage,
                                           iconTintColor: .accent,
                                           isExpanded: true,
                                           topButton: .none,
                                           actionButtons: [learnMoreAction, dismissAction])
        let topBannerView = TopBannerView(viewModel: viewModel)
        topBannerView.translatesAutoresizingMaskIntoConstraints = false
        return topBannerView
    }
}

private extension EUShippingNoticeTopBannerFactory {
    enum Localization {
        static let info = NSLocalizedString("When shipping to countries that follow European Union (EU) customs rules, " +
                                            "you must provide a clear, specific description of every item. Otherwise, " +
                                            "shipments may be delayed or interrupted at customs.",
                                            comment: "The EU notice banner content describing why some countries require special customs description")
        static let learnMore = NSLocalizedString("Learn more", comment: "Label for the banner Learn more button")
        static let dismiss = NSLocalizedString("Dismiss", comment: "Label for the banner Dismiss button")
    }

    enum String {
        static let shippingCustomsInstructionsForEUCountries = "https://www.usps.com/international/new-eu-customs-rules.htm"
    }
}
