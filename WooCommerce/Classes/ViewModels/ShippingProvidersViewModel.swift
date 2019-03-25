import Foundation
import Yosemite

final class ShippingProvidersViewModel {
    let title = NSLocalizedString("Shipping Providers",
                                  comment: "Title of view displaying all available Shipment Tracking Providers")

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Orders in sync.
    ///
    private(set) lazy var resultsController: ResultsController<StorageShipmentTrackingProviderGroup> = {
        let storageManager = AppDelegate.shared.storageManager
        let descriptor = NSSortDescriptor(keyPath: \ShipmentTrackingProviderGroup.name, ascending: false)

        return ResultsController<StorageShipmentTrackingProviderGroup>(storageManager: storageManager, sectionNameKeyPath: "name", sortedBy: [descriptor])
    }()
}
