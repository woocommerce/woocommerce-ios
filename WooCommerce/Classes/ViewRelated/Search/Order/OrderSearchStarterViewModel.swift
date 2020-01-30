
import Foundation
import UIKit
import Yosemite

/// ViewModel for `OrderSearchStarterViewController`.
///
/// This encapsulates all the `OrderStatus` data loading and `UITableViewCell` presentation.
///
final class OrderSearchStarterViewModel {
    private lazy var dataSource = DataSource()

    /// Start all the operations that this `ViewModel` is responsible for.
    ///
    /// This should only be called once in the lifetime of `OrderSearchStarterViewController`.
    ///
    /// - Parameters:
    ///     - tableView: The table to use for the results. This is not retained by this class.
    ///
    func activate(using tableView: UITableView) {
        tableView.dataSource = dataSource

        dataSource.registerCells(for: tableView)
        dataSource.startForwardingEvents(to: tableView)

        try? dataSource.performFetch()
    }
}


private extension OrderSearchStarterViewModel {
    /// Encpsulates data loading and presentation of the `UITableViewCells`.
    ///
    final class DataSource: NSObject, UITableViewDataSource {
        private lazy var storageManager = ServiceLocator.storageManager

        private lazy var resultsController: ResultsController<StorageOrderStatus> = {
            let descriptor = NSSortDescriptor(key: "slug", ascending: true)
            return ResultsController<StorageOrderStatus>(storageManager: storageManager,
                                                         sortedBy: [descriptor])
        }()

        /// Run the query to fetch all the `OrderStatus`.
        ///
        func performFetch() throws {
            try resultsController.performFetch()
        }

        /// Attach events so the `tableView` is always kept up to date.
        ///
        /// This should only be called once.
        ///
        func startForwardingEvents(to tableView: UITableView) {
            resultsController.startForwardingEvents(to: tableView)
        }

        /// Register the `UITableViewCells` that will be used.
        ///
        /// This should only be called once.
        ///
        func registerCells(for tableView: UITableView) {
            tableView.register(BasicTableViewCell.loadNib(),
                               forCellReuseIdentifier: BasicTableViewCell.reuseIdentifier)
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            resultsController.numberOfObjects
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: BasicTableViewCell.reuseIdentifier,
                                                     for: indexPath)
            let orderStatus = resultsController.object(at: indexPath)

            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            cell.textLabel?.text = orderStatus.name

            return cell
        }

        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            NSLocalizedString("Order Status", comment: "The section title for the list of Order statuses in the Order Search.")
        }
    }
}
