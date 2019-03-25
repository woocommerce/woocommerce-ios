import Foundation

final class ShippingProvidersViewModel {
    let title = NSLocalizedString("Shipping Providers",
                                  comment: "Title of view displaying all available Shipment Tracking Providers")

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Orders in sync.
    ///
//    private(set) lazy var resultsController: ResultsController<ShipmentTrackingProviderGroup> = {
//        let storageManager = AppDelegate.shared.storageManager
//        let descriptor = NSSortDescriptor(keyPath: \StorageOrder.dateCreated, ascending: false)
//
//        return ResultsController<ShipmentTrackingProviderGroup>(storageManager: storageManager, sectionNameKeyPath: "normalizedAgeAsString", sortedBy: [descriptor])
//    }()
}
