import SwiftUI
import Networking

/// `SwiftUI` wrapper for `OrderStatusListViewController`
///
struct OrderStatusList: UIViewControllerRepresentable {

    let siteID: Int64

    /// Preselected order status.
    ///
    let status: OrderStatusEnum

    /// Whether to automatically confirm the order status when it is selected.
    ///
    /// Defaults to `false`.
    ///
    let isSelectionAutoConfirmed: Bool

    /// Closure to be invoked when the status is updated.
    ///
    var didConfirmSelection: ((OrderStatusEnum) -> Void)

    func makeUIViewController(context: Context) -> WooNavigationController {
        let statusList = OrderStatusListViewController(siteID: siteID, status: status, isSelectionAutoConfirmed: isSelectionAutoConfirmed)

        statusList.didConfirmSelection = { [weak statusList] selectedStatus in
            statusList?.dismiss(animated: true) {
                didConfirmSelection(selectedStatus)
            }
        }

        let navigationController = WooNavigationController(rootViewController: statusList)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: WooNavigationController, context: Context) {
        // No-op
    }
}
