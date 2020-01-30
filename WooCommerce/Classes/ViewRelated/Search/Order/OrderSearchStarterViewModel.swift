
import Foundation
import UIKit
import Yosemite

final class OrderSearchStarterViewModel {
    private lazy var dataSource = DataSource()

    func configureDataSource(for tableView: UITableView) {
        tableView.dataSource = dataSource

        dataSource.registerCells(for: tableView)
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
