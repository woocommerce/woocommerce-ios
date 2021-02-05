import Foundation
import Yosemite
import class AutomatticTracks.CrashLogging

final class OrderStatusListViewModel {
    private var status: OrderStatusEnum?
    private var dataSource: OrderStatusListDataSource

    init(status: OrderStatusEnum, dataSource: OrderStatusListDataSource) {
        self.status = status
        self.dataSource = dataSource
    }

    func configureResultsController(tableView: UITableView) {
        dataSource.startForwardingEvents(to: tableView)
        do {
            try dataSource.performFetch()
        } catch {
            CrashLogging.logError(error)
        }
        tableView.reloadData()
    }

    /// Return the number of statuses for the view.
    ///
    func statusCount() -> Int {
        dataSource.statusCount()
    }

    /// Return the index of the current order status.
    ///
    func indexOfCurrentOrderStatus() -> IndexPath? {
        guard let foundStatus = dataSource.statuses().filter({ $0.status == status }).first else {
            return nil
        }
        guard let row = dataSource.statuses().firstIndex(of: foundStatus) else {
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
        guard indexPath.row < statusCount() else {
            return nil
        }
        let status = dataSource.statuses()[indexPath.row].status
        return status
    }

    /// Return the status name at the given index.
    ///
    func statusName(at indexPath: IndexPath) -> String? {
        guard indexPath.section == 0 else {
            return nil
        }
        guard indexPath.row < statusCount() else {
            return nil
        }
        let status = dataSource.statuses()[indexPath.row]
        return status.name
    }
}
