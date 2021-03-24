import UIKit

/// Generates top banner view that is shown at the top of variation list screen when at least one variation is missing a price.
///
final class ShippingLabelAddressTopBannerFactory {
    static func addressErrorTopBannerView(openMapPressed: @escaping () -> Void,
                                          contactCustomerPressed: @escaping () -> Void) -> TopBannerView {
        let openMapAction = TopBannerViewModel.ActionButton(title: Localization.openMapAction) {
            openMapPressed()
        }
        let contactCustomerAction = TopBannerViewModel.ActionButton(title: Localization.contactCustomerAction) {
            contactCustomerPressed()
        }
        let actions = [openMapAction, contactCustomerAction]
        let viewModel = TopBannerViewModel(title: nil,
                                           infoText: Localization.info,
                                           icon: Constants.icon,
                                           isExpanded: true,
                                           topButton: .none,
                                           actionButtons: actions,
                                           type: .warning)
        return TopBannerView(viewModel: viewModel)
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
        static let openMapAction = NSLocalizedString("Open Map", comment: "Open Map action in Shipping Label Address Validation.")
        static let contactCustomerAction = NSLocalizedString("Contact Customer", comment: "Contact Customer action in Shipping Label Address Validation.")
    }
}
