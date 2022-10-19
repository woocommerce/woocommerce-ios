import Foundation
import SwiftUI

/// `SwiftUI` wrapper for `SearchViewController` using `CustomerSearchUICommand`
/// TODO: Make it generic
struct OrderCustomerListView: UIViewControllerRepresentable {

    let siteID: Int64

    func makeUIViewController(context: Context) -> WooNavigationController {

        let viewController = SearchViewController(
            storeID: siteID,
            command: CouponSearchUICommand(siteID: siteID),
            // TODO: replace SearchUICommand
            cellType: TitleAndSubtitleAndStatusTableViewCell.self,
            // Must conform to SearchResultCell.
            // TODO: Proper cell for this cellType.
            cellSeparator: .none
        )
        let navigationController = WooNavigationController(rootViewController: viewController)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // nope
    }
}
