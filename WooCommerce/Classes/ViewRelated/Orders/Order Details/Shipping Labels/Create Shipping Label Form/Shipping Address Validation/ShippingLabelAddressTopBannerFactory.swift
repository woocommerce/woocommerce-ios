import UIKit

/// Generates top banner view that is shown at the top of variation list screen when at least one variation is missing a price.
///
final class ShippingLabelAddressTopBannerFactory {
    static func addressErrorTopBannerView() -> TopBannerSwifty {
        let viewModel =  TopBannerSwiftyViewModel(title: nil,
                                                  infoText: Localization.info,
                                                  icon: Constants.icon,
                                                  expandable: true,
                                                  topButton: .none,
                                                  actionButtons: [],
                                                  type: .warning)
        return TopBannerSwifty(viewModel: viewModel)
    }
}

private extension ShippingLabelAddressTopBannerFactory {
    enum Constants {
        static let icon = UIImage.infoOutlineImage
    }

    enum Localization {
        static let info = NSLocalizedString("We were unable to automatically verify the shipping address. " +
                                                "View on Apple Maps or try contacting the customer to make sure the address is correct.",
                                            comment: "Banner caption in Shipping Label Address Validation when the address can't be verified.")
    }
}
