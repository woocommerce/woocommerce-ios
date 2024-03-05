import Foundation
import Yosemite
import SwiftUI

/// `SwiftUI` wrapper for `CustomerSelectorViewController` embedded in a WooNavigationController
///
struct CustomerSelectorView: UIViewControllerRepresentable {
    let siteID: Int64
    let configuration: CustomerSelectorViewController.Configuration
    let addressFormViewModel: CreateOrderAddressFormViewModel
    let onCustomerSelected: (Customer) -> Void

    func makeUIViewController(context: Context) -> WooNavigationController {
        let viewController = CustomerSelectorViewController(
            siteID: siteID,
            configuration: configuration,
            addressFormViewModel: addressFormViewModel,
            onCustomerSelected: onCustomerSelected
        )

        let navigationController = WooNavigationController(rootViewController: viewController)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // not implemented
    }
}
