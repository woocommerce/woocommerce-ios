
import Foundation
import UIKit
import Yosemite

final class OrderSearchStarterViewModel {
    private lazy var dataSource = DataSource()

    func configureDataSource(for tableView: UITableView) {
        tableView.dataSource = dataSource

        dataSource.startForwardingEvents(to: tableView)
        try? dataSource.performFetch()
    }
}


private extension OrderSearchStarterViewModel {
    final class DataSource: NSObject, UITableViewDataSource {
        private lazy var storageManager = ServiceLocator.storageManager

        private lazy var resultsController: ResultsController<StorageOrderStatus> = {
            let descriptor = NSSortDescriptor(key: "slug", ascending: true)
            return ResultsController<StorageOrderStatus>(storageManager: storageManager,
                                                         sortedBy: [descriptor])
        }()

        func performFetch() throws {
            try resultsController.performFetch()
        }

        func startForwardingEvents(to tableView: UITableView) {
            resultsController.startForwardingEvents(to: tableView)
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            resultsController.numberOfObjects
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let status = resultsController.object(at: indexPath)

            let cell = UITableViewCell()
            cell.textLabel?.text = status.name

            return cell
        }

        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            NSLocalizedString("Order Status", comment: "The section title for the list of Order statuses in the Order Search.")
        }
    }
}
