import Foundation
import Yosemite
import SwiftUI

/// `SwiftUI` wrapper for `CustomerSelectorViewController` embedded in a WooNavigationController
///
struct CustomerSelectorView: UIViewControllerRepresentable {
    let siteID: Int64

    func makeUIViewController(context: Context) -> WooNavigationController {
        let viewController = CustomerSelectorViewController(siteID: siteID)

        let navigationController = WooNavigationController(rootViewController: viewController)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // not implemented
    }
}
