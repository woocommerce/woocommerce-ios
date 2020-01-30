
import Foundation
import UIKit
import Yosemite

final class OrderSearchStarterViewModel {
    private lazy var dataSource = DataSource()

    func configureDataSource(for tableView: UITableView) {
        dataSource.startForwardingEvents(to: tableView)
    }
}


extension OrderSearchStarterViewModel {
    class DataSource: NSObject, UITableViewDataSource {
        private lazy var storageManager = ServiceLocator.storageManager

        private lazy var resultsController: ResultsController<StorageOrderStatus> = {
            let descriptor = NSSortDescriptor(key: "slug", ascending: true)
            return ResultsController<StorageOrderStatus>(storageManager: storageManager,
                                                         sortedBy: [descriptor])
        }()

        func startForwardingEvents(to tableView: UITableView) {
            resultsController.startForwardingEvents(to: tableView)
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 0
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            return UITableViewCell()
        }
    }
}
