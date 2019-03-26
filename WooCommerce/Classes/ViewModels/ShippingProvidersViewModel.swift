import Foundation
import UIKit
import Yosemite

final class ShippingProvidersViewModel {
    private(set) var groups = [StorageShipmentTrackingProviderGroup]()

    let title = NSLocalizedString("Shipping Providers",
                                  comment: "Title of view displaying all available Shipment Tracking Providers")

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) StorageShipmentTrackingProviderGroup in sync.
    ///
    private(set) lazy var resultsController: ResultsController<StorageShipmentTrackingProviderGroup> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController<StorageShipmentTrackingProviderGroup>(storageManager: storageManager,
                                                                       sectionNameKeyPath: "name",
                                                                       matching: predicate,
                                                                       sortedBy: [descriptor])
    }()

    /// Setup: Results Controller
    ///
    func configureResultsController(table: UITableView) {
        resultsController.startForwardingEvents(to: table)
        try? resultsController.performFetch()
    }
}
