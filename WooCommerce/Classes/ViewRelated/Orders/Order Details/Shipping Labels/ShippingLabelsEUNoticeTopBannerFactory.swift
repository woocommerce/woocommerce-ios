import Foundation

final class ShippingLabelsEUNoticeTopBannerFactory {
    func createTopBanner() -> TopBannerView {
        let viewModel = TopBannerViewModel(
                title: Localization.title,
                infoText: Localization.info,
                icon: .infoImage,
                isExpanded: true,
                topButton: .none)

        return TopBannerView(viewModel: viewModel)
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
