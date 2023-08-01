import Foundation
import Yosemite
import SwiftUI

/// `SwiftUI` wrapper for `CustomerSelectorViewController` embedded in a WooNavigationController
///
struct CustomerSelectorView: UIViewControllerRepresentable {
    let siteID: Int64
    let addressFormViewModel: CreateOrderAddressFormViewModel
    let onCustomerSelected: (Customer) -> Void

    func makeUIViewController(context: Context) -> WooNavigationController {
        let viewController = CustomerSelectorViewController(siteID: siteID, addressFormViewModel: addressFormViewModel, onCustomerSelected: onCustomerSelected)

        let navigationController = WooNavigationController(rootViewController: viewController)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // not implemented
    }
}
