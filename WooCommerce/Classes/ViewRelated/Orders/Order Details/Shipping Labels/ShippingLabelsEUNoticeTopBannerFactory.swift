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
                title: Localization.title,
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
        static let title = NSLocalizedString("", comment: "")
        static let info = NSLocalizedString("", comment: "")
        static let learnMore = NSLocalizedString("", comment: "")
        static let dismiss = NSLocalizedString("", comment: "")
    }
}
