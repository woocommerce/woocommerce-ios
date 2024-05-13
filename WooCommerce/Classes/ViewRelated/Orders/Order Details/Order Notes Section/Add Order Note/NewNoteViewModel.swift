import Foundation
import Yosemite
import protocol WooFoundation.Analytics

final class NewNoteViewModel {
    let order: Order
    let orderNotes: [OrderNote]
    var onDidFinishEditing: ((OrderNote) -> Void)?
    let analytics: Analytics

    var siteID: Int64 {
        order.siteID
    }

    var orderID: Int64 {
        order.orderID
    }

    var orderStatus: String {
        order.status.rawValue
    }

    var orderNumber: String {
        order.number
    }

    init(order: Order, orderNotes: [OrderNote], analytics: Analytics = ServiceLocator.analytics) {
        self.order = order
        self.orderNotes = orderNotes
        self.analytics = analytics
    }
}

// MARK: - Tracking
//
extension NewNoteViewModel {
    func track(_ stat: WooAnalyticsStat, withProperties properties: [AnyHashable: Any]? = nil, withError: Error? = nil) {
        analytics.track(stat, properties: properties, error: withError)
    }

    func trackOrderNoteAddButtonTapped() {
        analytics.track(.orderNoteAddButtonTapped)
    }

    func trackOrderNoteAdd(_ isCustomerNote: Bool) {
        analytics.track(.orderNoteAdd, withProperties: [
            "parent_id": orderID,
            "status": orderStatus,
            "type": isCustomerNote ? "customer" : "private"]
        )
    }

    func trackOrderNoteEmailCustomerToggled(_ stateValue: String) {
        analytics.track(.orderNoteEmailCustomerToggled, withProperties: ["state": stateValue])
    }
}
