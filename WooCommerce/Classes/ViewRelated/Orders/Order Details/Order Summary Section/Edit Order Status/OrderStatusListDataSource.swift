import Foundation
import UIKit
import Yosemite

final class OrderStatusListDataSource {
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld && slug != %@",
                                    siteID,
                                    OrderStatusEnum.refunded.rawValue)
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)
        return ResultsController<StorageOrderStatus>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
    }

    func performFetch() throws {
        try statusResultsController.performFetch()
    }

    func statusCount() -> Int {
        statusResultsController.numberOfObjects
    }

    func statuses() -> [OrderStatus] {
        statusResultsController.fetchedObjects
    }

    func startForwardingEvents(to tableView: UITableView) {
        statusResultsController.startForwardingEvents(to: tableView)
    }
}
