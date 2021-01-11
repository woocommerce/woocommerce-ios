import Combine
import Yosemite

final class OrderFulfillmentUseCase {
    struct FulfillmentError: Error {
        let message: String
        let retry: () -> FulfillmentProcess
    }

    struct FulfillmentProcess {
        let undo: () -> FulfillmentProcess
        let future: Future<Void, FulfillmentError>
    }

    private enum Context {
        case fulfill
        case undo
    }

    private let stores: StoresManager
    private let analytics: Analytics = ServiceLocator.analytics
    private let order: Order

    init(order: Order, stores: StoresManager) {
        self.order = order
        self.stores = stores
    }

    func fulfill() -> FulfillmentProcess {
        dispatchStatusUpdateAction(order: order, status: .completed, context: .fulfill)
    }

    private func dispatchStatusUpdateAction(order: Order,
                                            status targetStatus: OrderStatusEnum,
                                            context: Context) -> FulfillmentProcess {
        let sourceStatus = order.status

        analytics.track(.orderStatusChange, withProperties: ["id": order.orderID,
                                                             "from": sourceStatus.rawValue,
                                                             "to": targetStatus.rawValue])

        let future: Future<Void, FulfillmentError> = Future { promise in
            let action = OrderAction.updateOrder(siteID: order.siteID, orderID: order.orderID, status: targetStatus) { error in
                guard let error = error else {
                    NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
                    self.analytics.track(.orderStatusChangeSuccess)
                    promise(.success(()))
                    return
                }

                self.analytics.track(.orderStatusChangeFailed, withError: error)
                DDLogError("⛔️ Order Update Failure: [\(order.orderID).status = \(targetStatus)]. Error: \(error)")

                let fulfillmentError = FulfillmentError(
                    message: self.makeErrorMessage(order: order, context: context),
                    retry: {
                        self.dispatchStatusUpdateAction(order: order, status: targetStatus, context: context)
                    }
                )
                promise(.failure(fulfillmentError))
            }

            self.stores.dispatch(action)
        }

        return FulfillmentProcess(undo: {
            self.analytics.track(.orderStatusChangeUndo, withProperties: ["id": order.orderID])

            return self.dispatchStatusUpdateAction(order: order, status: sourceStatus, context: .undo)
        }, future: future)
    }

    private func makeErrorMessage(order: Order, context: Context) -> String {
        switch context {
        case .fulfill:
            return Localization.fulfillmentError(orderID: order.orderID)
        case .undo:
            return Localization.undoError(orderID: order.orderID)
        }
    }
}

private extension OrderFulfillmentUseCase {
    enum Localization {
        static func fulfillmentError(orderID: Int64) -> String {
            let format = NSLocalizedString(
                "Unable to fulfill order #%1$d",
                comment: "Content of error presented when Mark Order Completed failed. "
                    + "It reads: Unable to fulfill order #{order number}. "
                    + "Parameters: %1$d - order number"
            )
            return String.localizedStringWithFormat(format, orderID)
        }

        static func undoError(orderID: Int64) -> String {
            let format = NSLocalizedString(
                "Failed to undo fulfillment of order #%1$d",
                comment: "Content of error presented when undo of Mark Order Completed failed. "
                    + "It reads: Failed to undo fulfillment of order #{order number}. "
                    + "Parameters: %1$d - order number"
            )
            return String.localizedStringWithFormat(format, orderID)
        }
    }
}
