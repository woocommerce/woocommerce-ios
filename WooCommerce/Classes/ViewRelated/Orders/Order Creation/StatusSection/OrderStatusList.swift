import SwiftUI
import Networking

/// `SwiftUI` wrapper for `OrderStatusListViewController`
///
struct OrderStatusList: UIViewControllerRepresentable {

    let siteID: Int64

    /// Preselected order status.
    ///
    let status: OrderStatusEnum

    /// Closure to be invoked when the status is updated.
    ///
    var didSelectApply: ((OrderStatusEnum) -> Void)

    func makeUIViewController(context: Context) -> WooNavigationController {
        let viewModel = OrderStatusListViewModel(siteID: siteID,
                                                 status: status)
        let statusList = OrderStatusListViewController(viewModel: viewModel)

        viewModel.didSelectCancel = { [weak statusList] in
            statusList?.dismiss(animated: true, completion: nil)
        }

        viewModel.didSelectApply = { [weak statusList] selectedStatus in
            statusList?.dismiss(animated: true) {
                didSelectApply(selectedStatus)
            }
        }

        let navigationController = WooNavigationController(rootViewController: statusList)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: WooNavigationController, context: Context) {
        // No-op
    }
}
