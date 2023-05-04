import Foundation

final class ShippingLabelsEUNoticeTopBannerFactory {
    func createTopBanner() -> TopBannerView {
        let viewModel = TopBannerViewModel(title: Localization.title,
                infoText: Localization.info,
                icon: .infoImage,
                topButton: .none)

        return TopBannerView(viewModel: viewModel)
    }
}

private extension ShippingLabelsEUNoticeTopBannerFactory {
    enum Localization {
        static let title = NSLocalizedString("")
        static let info = NSLocalizedString("")
        static let learnMore = NSLocalizedString("")
        static let dismiss = NSLocalizedString("")
    }
}
