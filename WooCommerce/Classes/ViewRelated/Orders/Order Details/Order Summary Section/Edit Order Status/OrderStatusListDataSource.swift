import Foundation
import UIKit
import Yosemite
import protocol Storage.StorageManagerType

final class OrderStatusListDataSource {

    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let predicate = NSPredicate(format: "siteID == %lld && slug != %@",
                                    siteID,
                                    OrderStatusEnum.refunded.rawValue)
        return ResultsController<StorageOrderStatus>(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    private let siteID: Int64

    /// Used to inject as a dependency to `ResultsController`.
    private let storageManager: StorageManagerType

    init(siteID: Int64, storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.storageManager = storageManager
    }

    func performFetch() throws {
        try statusResultsController.performFetch()
    }

    func statusCount() -> Int {
        statusResultsController.numberOfObjects
    }

    func statuses() -> [OrderStatus] {
        statusResultsController.fetchedObjects.sorted(by: { $1.status > $0.status })
    }

    func startForwardingEvents(to tableView: UITableView) {
        statusResultsController.startForwardingEvents(to: tableView)
    }
}
