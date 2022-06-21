import Foundation
import Yosemite
import class AutomatticTracks.CrashLogging
import protocol Storage.StorageManagerType

final class OrderStatusListViewModel {
    private let status: OrderStatusEnum?
    private var dataSource: OrderStatusListDataSource

    /// The index of the status stored in the database when list view is presented
    ///
    private(set) var initialStatus: IndexPath?

    /// The index of (new) order status selected by the user tapping on a table row.
    ///
    var indexOfSelectedStatus: IndexPath? {
        didSet {
            let selectedNewStatus = initialStatus != indexOfSelectedStatus
            switch (selectedNewStatus, autoConfirmSelection) {
            case (true, false):
                shouldEnableApplyButton = true // New status with manual confirmation
            case (true, true):
                confirmSelectedStatus() // New status with automatic confirmation
            case (false, _):
                shouldEnableApplyButton = false // No new status
            }
        }
    }

    /// Whether the Apply button should be enabled.
    ///
    private(set) var shouldEnableApplyButton: Bool = false

    /// Whether to automatically confirm the order status when it is selected.
    ///
    /// Defaults to `false`.
    ///
    let autoConfirmSelection: Bool

    /// A closure to be called when the VC wants its creator to dismiss it without saving changes.
    ///
    var didCancelSelection: (() -> Void)?

    /// A closure to be called when the VC wants its creator to change the order status to the selected status and dismiss it.
    ///
    var didApplySelection: ((OrderStatusEnum) -> Void)?

    init(siteID: Int64,
         status: OrderStatusEnum,
         autoConfirmSelection: Bool = false,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.status = status
        self.dataSource = OrderStatusListDataSource(siteID: siteID, storageManager: storageManager)
        self.autoConfirmSelection = autoConfirmSelection

        configureDataSource()
        configureInitialStatus()
    }

    func configureResultsController(tableView: UITableView) {
        dataSource.startForwardingEvents(to: tableView)
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

    func confirmSelectedStatus() {
        guard let indexOfSelectedStatus = indexOfSelectedStatus else {
            didCancelSelection?()
            return
        }
        guard let selectedStatus = status(at: indexOfSelectedStatus) else {
            didCancelSelection?()
            return
        }
        didApplySelection?(selectedStatus)
    }
}

private extension OrderStatusListViewModel {
    /// Fetches the list of order statuses.
    ///
    func configureDataSource() {
        do {
            try dataSource.performFetch()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    /// Sets the index of the initial order status.
    ///
    func configureInitialStatus() {
        initialStatus = indexOfCurrentOrderStatus()
    }
}
