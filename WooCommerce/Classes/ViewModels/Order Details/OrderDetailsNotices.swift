import Foundation
import Yosemite

final class OrderDetailsNotices {
    static let shared = OrderDetailsNotices()
    /// Displays the `Unable to delete tracking` Notice.
    ///
    func displayDeleteTrackingErrorNotice(order: Order, tracking: ShipmentTracking, onAction: @escaping () -> Void) {
        let title = String.localizedStringWithFormat(Localization.deleteTracking, order.orderID)
        let notice = Notice(title: title,
                            message: nil,
                            feedbackType: .error,
                            actionTitle: Localization.retry) {
                                onAction()
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Displays the `Unable to trash order` Notice.
    ///
    func displayTrashOrderErrorNotice(order: Order, onAction: @escaping () -> Void) {
        let title = String.localizedStringWithFormat(Localization.trashOrder, order.orderID)
        let notice = Notice(title: title,
                            message: nil,
                            feedbackType: .error,
                            actionTitle: Localization.retry) {
                                onAction()
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}

private extension OrderDetailsNotices {
    enum Localization {
        // Here to be added to Localizable.strings so it can be looked up by the `LocalizedStringResource` above
        static let deleteTracking = NSLocalizedString(
                     "orderDetail.deleteTracking.notice.title",
                     value: "Unable to delete tracking for order #%1$d",
                     comment: "Content of error presented when Delete Shipment Tracking Action Failed. "
                     + "It reads: Unable to delete tracking for order #{order number}. "
                     + "Parameters: %1$d - order number")
        static let retry = NSLocalizedString("OrderDetail.retry.notice.button",
                                             value: "Retry",
                                             comment: "Retry Action inside notice")
        static let trashOrder = NSLocalizedString(
                     "OrderDetail.trashOrder.notice.title",
                     value: "Unable to trash the order #%1$d",
                     comment: "Content of error presented when Trash Order Action Failed. "
                     + "It reads: Unable to trash the order #{order number}. "
                     + "Parameters: %1$d - order number")
    }
}
