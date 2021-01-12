import Combine
import Yosemite

/// Dispatches a network call for fulfilling an `Order`. This also provides actions for
/// undoing the fulfillment and retrying failed network calls.
///
/// The UI is mainly handled by `OrderFulfillmentNoticePresenter`.
///
final class OrderFulfillmentUseCase {
    /// Represents a failed fulfillment, undo, or retry.
    struct FulfillmentError: Error {
        /// The type of activity that failed.
        let activity: Activity
        /// An error message that should be presented to the user.
        let message: String
        /// A function that can be called to retry the activity represented by this error.
        ///
        /// The retry is typically initiated by the user.
        let retry: () -> FulfillmentProcess
    }

    /// An ongoing or completed fulfillment, undo, or retry.
    struct FulfillmentProcess {
        /// The type of the ongoing or completed activity.
        let activity: Activity
        /// An observable result of the activity.
        let result: Future<Void, FulfillmentError>
        /// A function that can be used to undo the activity.
        ///
        /// For example, if the activity is `.fulfill`, which changes the `Order`'s `status` to
        /// `completed`, then this function will dispatch a network call to revert the `status`
        /// to the previously known `status` (e.g. `processing`, `on-hold`, etc.).
        let undo: () -> FulfillmentProcess
    }

    /// Defines the type of activity that this class handles.
    enum Activity {
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

    /// Mark the `self.order` as `.completed`.
    ///
    /// - Returns: An object containing the future result and a way to undo the change.
    func fulfill() -> FulfillmentProcess {
        dispatchStatusUpdateAction(order: order, status: .completed, activity: .fulfill)
    }

    /// Executes the network call and, eventually, the update of the `Order` in the database.
    ///
    /// This recurring function is used by all types of activities handled by this class.
    private func dispatchStatusUpdateAction(order: Order,
                                            status targetStatus: OrderStatusEnum,
                                            activity: Activity) -> FulfillmentProcess {
        analytics.track(.orderStatusChange, withProperties: ["id": order.orderID,
                                                             "from": order.status.rawValue,
                                                             "to": targetStatus.rawValue])

        let result: Future<Void, FulfillmentError> = Future { promise in
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
                    activity: activity,
                    message: self.makeErrorMessage(order: order, activity: activity),
                    retry: {
                        self.dispatchStatusUpdateAction(order: order, status: targetStatus, activity: activity)
                    }
                )
                promise(.failure(fulfillmentError))
            }

            self.stores.dispatch(action)
        }

        return FulfillmentProcess(
            activity: activity,
            result: result,
            undo: {
                self.analytics.track(.orderStatusChangeUndo, withProperties: ["id": order.orderID])

                return self.dispatchStatusUpdateAction(order: order, status: order.status, activity: .undo)
            }
        )
    }

    private func makeErrorMessage(order: Order, activity: Activity) -> String {
        switch activity {
        case .fulfill:
            return Localization.fulfillmentError(orderID: order.orderID)
        case .undo:
            return Localization.undoError(orderID: order.orderID)
        }
    }
}

extension OrderFulfillmentUseCase {
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
