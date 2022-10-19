import Foundation
import SwiftUI

/// `SwiftUI` wrapper for `SearchViewController`
///
struct OrderCustomerListView: UIViewControllerRepresentable {
    
    let storeID: Int64
    let command: CouponSearchUICommand // TODO: Make CustomerSearchUICommand
    let cellType: UITableViewCell
    
    func makeUIViewController(context: Context) -> WooNavigationController {
        //let vm =
        let viewController = SearchViewController(
            storeID: storeID,
            command: command,
            cellType: TitleAndSubtitleAndStatusTableViewCell.self,
            // Must conform to SearchResultCell.
            // TODO: Proper cell for this cellType.
            cellSeparator: .none
        )
        let navigationController = WooNavigationController(rootViewController: viewController)
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
