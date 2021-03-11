import UIKit

/// Generates top banner view that is shown at the top of variation list screen when at least one variation is missing a price.
///
final class ShippingLabelSuggestedAddressTopBannerFactory {
    static func topBannerView() -> TopBannerSwifty {
        let viewModel = TopBannerSwiftyViewModel(title: nil,
                                                 infoText: Localization.info,
                                                 icon: Constants.icon,
                                                 expandable: true,
                                                 topButton: .none,
                                                 type: .warning)
        return TopBannerSwifty(viewModel: viewModel)
    }
}

private extension ShippingLabelSuggestedAddressTopBannerFactory {
    enum Constants {
        static let icon = UIImage.infoOutlineImage
    }

    enum Localization {
        static let info = NSLocalizedString("We have slightly modified the address entered. " +
                                                "If correct, please use the suggested address to ensure accurate delivery.",
                                            comment: "Banner caption in Shipping Label Address when there is a suggested address.")
    }
}
