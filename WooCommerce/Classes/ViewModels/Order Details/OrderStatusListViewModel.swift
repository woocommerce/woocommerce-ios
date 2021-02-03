import Foundation
import Yosemite

class OrderStatusListViewModel {
    private var orderStatuses = [OrderStatus]()
    private var orderStatus: OrderStatusEnum?

    /// Provide a means for the view to be notified when this view model changes.
    private var onUpdate: (() -> ())?

    /// Update the statuses.
    func updateStatuses(newStatuses: [OrderStatus]) {
        orderStatuses = newStatuses
        onUpdate?()
    }

    /// Set the current order status.
    func setCurrentOrderStatus(newStatus: OrderStatusEnum) {
        orderStatus = newStatus
        onUpdate?()
    }

    /// Return the number of statuses for the view.
    ///
    func statusCount() -> Int {
        orderStatuses.count
    }

    /// Return the index of the current order status.
    ///
    func indexOfCurrentOrderStatus() -> IndexPath? {
        guard let orderStatus = self.orderStatus else {
            return nil
        }
        guard let foundStatus = orderStatuses.filter({ $0.status == orderStatus }).first else {
            return nil
        }
        guard let row = orderStatuses.firstIndex(of: foundStatus) else {
            return nil
        }
        return IndexPath(row: row, section: 0)
    }

    /// Return the status enum at the given index.
    ///
    func status(at indexPath: IndexPath) -> OrderStatusEnum? {
        guard indexPath.section == 0 else {
            return nil
        }
        guard indexPath.row < orderStatuses.count else {
            return nil
        }
        let status = orderStatuses[indexPath.row].status
        return status
    }

    /// Return the status name at the given index.
    ///
    func statusName(at indexPath: IndexPath) -> String? {
        guard indexPath.section == 0 else {
            return nil
        }
        guard indexPath.row < orderStatuses.count else {
            return nil
        }
        let status = orderStatuses[indexPath.row]
        return status.name
    }
}
