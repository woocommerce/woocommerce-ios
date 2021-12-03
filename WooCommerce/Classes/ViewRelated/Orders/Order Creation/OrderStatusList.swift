import SwiftUI
import Networking

/// `SwiftUI` wrapper for `SurveyCoordinatingController`
///
struct OrderStatusList: UIViewControllerRepresentable {

    let siteID: Int64
    let status: OrderStatusEnum

    /// Closure to be invoked when the status is updated.
    ///
    var didSelectApply: ((OrderStatusEnum) -> Void)

    func makeUIViewController(context: Context) -> WooNavigationController {
        let statusList = OrderStatusListViewController(siteID: siteID, status: status)

        statusList.didSelectCancel = { [weak statusList] in
            statusList?.dismiss(animated: true, completion: nil)
        }

        statusList.didSelectApply = { [weak statusList] selectedStatus in
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
