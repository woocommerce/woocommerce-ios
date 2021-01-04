import Foundation
import Yosemite

final class OrderDetailsNotices {
    /// Displays the `Unable to delete tracking` Notice.
    ///
    func displayDeleteErrorNotice(order: Order, tracking: ShipmentTracking, onAction: @escaping () -> Void) {
        let titleFormat = NSLocalizedString(
            "Unable to delete tracking for order #%1$d",
            comment: "Content of error presented when Delete Shipment Tracking Action Failed. "
                + "It reads: Unable to delete tracking for order #{order number}. "
                + "Parameters: %1$d - order number"
        )
        let title = String.localizedStringWithFormat(titleFormat, order.orderID)
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
