import Foundation
import Yosemite

final class OrderDetailsNotices {
    /// Displays the `Unable to delete tracking` Notice.
    ///
    func displayDeleteErrorNotice(order: Order, tracking: ShipmentTracking, onAction: @escaping () -> Void) {
        let title = NSLocalizedString(
            "Unable to delete tracking for order #\(order.orderID)",
            comment: "Content of error presented when Delete Shipment Tracking Action Failed. It reads: Unable to delete tracking for order #{order number}"
        )
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title,
                            message: nil,
                            feedbackType: .error,
                            actionTitle: actionTitle) {
                                onAction()
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}
