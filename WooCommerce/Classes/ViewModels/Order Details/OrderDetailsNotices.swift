import Foundation
import Yosemite

final class OrderDetailsNotices {
    /// Displays a Notice onscreen, indicating that the current Order has been deleted from the Store.
    ///
    func displayOrderDeletedNotice(order: Order) {
        let message = String.localizedStringWithFormat(
            NSLocalizedString(
                "Order %@ has been deleted from your store",
                comment: "Displayed whenever an Order gets deleted. It reads: Order {order number} has been deleted from your store."
            ),
            order.number
        )

        let notice = Notice(title: message, feedbackType: .error)
        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

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
