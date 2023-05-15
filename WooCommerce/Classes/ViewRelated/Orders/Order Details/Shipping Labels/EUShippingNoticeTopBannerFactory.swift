import Foundation

final class EUShippingNoticeTopBannerFactory {
    static func createWarningBanner(onDismissPressed: @escaping () -> Void,
                                    onLearnMorePressed: @escaping () -> Void) -> TopBannerView {
        return createTopBanner(contentText: Localization.warningInfo, onDismissPressed: onDismissPressed, onLearnMorePressed: onLearnMorePressed)
    }

    static func createInstructionsBanner(onDismissPressed: @escaping () -> Void,
                                         onLearnMorePressed: @escaping () -> Void) -> TopBannerView {
        return createTopBanner(contentText: Localization.instructionsInfo, onDismissPressed: onDismissPressed, onLearnMorePressed: onLearnMorePressed)
    }

    private static func createTopBanner(contentText: String,
                                        onDismissPressed: @escaping () -> Void,
                                        onLearnMorePressed: @escaping () -> Void) -> TopBannerView {
        let learnMoreAction = TopBannerViewModel.ActionButton(title: Localization.learnMore) { _ in
            onLearnMorePressed()
        }

        let dismissAction = TopBannerViewModel.ActionButton(title: Localization.dismiss) { _ in
            onDismissPressed()
        }

        let viewModel = TopBannerViewModel(title: nil,
                                           infoText: contentText,
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

extension EUShippingNoticeTopBannerFactory {
    enum InfoType {
        case warning
        case instructions

        var localizedRawValue: String {
            switch self {
            case .warning:
                return Localization.warningInfo
            case .instructions:
                return Localization.instructionsInfo
            }
        }
    }

    private enum Localization {
        static let warningInfo = NSLocalizedString("When shipping to countries that follow European Union (EU) customs rules, " +
                                                   "you must provide a clear, specific description of every item. Otherwise, " +
                                                   "shipments may be delayed or interrupted at customs.",
                                                   comment: "The EU notice banner content describing why some countries require special customs description")
        static let instructionsInfo = NSLocalizedString("Shipping to countries that follow European Union (EU) customs rules now " +
                                                        "requires you clearly describe every item. For example, if you are sending " +
                                                        "clothing, you must indicate what type of clothing (e.g., men’s shirts, girl’s vest, boy’s jacket) " +
                                                        "for the description to be acceptable. Otherwise, shipments may be delayed or interrupted at customs. ",
                                                        comment: "The EU notice banner content describing how the shipping customs shall be configured")
        static let learnMore = NSLocalizedString("Learn more", comment: "Label for the banner Learn more button")
        static let dismiss = NSLocalizedString("Dismiss", comment: "Label for the banner Dismiss button")
    }
}
