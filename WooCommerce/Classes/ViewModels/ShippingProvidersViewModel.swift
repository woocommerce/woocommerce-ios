import Foundation
import UIKit
import Yosemite

/// Encapsulates the data necessary to render a list of shipment providers
///
final class ShippingProvidersViewModel {
    let order: Order

    let title = NSLocalizedString("Shipping Providers",
                                  comment: "Title of view displaying all available Shipment Tracking Providers")

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) StorageShipmentTrackingProviderGroup in sync.
    ///
    private(set) lazy var resultsController: ResultsController<StorageShipmentTrackingProvider> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID == %lld",
                                    StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)

        let groupNameKeyPath = #keyPath(StorageShipmentTrackingProvider.group.name)
        let providerNameKeyPath = #keyPath(StorageShipmentTrackingProvider.name)

        let providerGroupDescriptor = NSSortDescriptor(key: groupNameKeyPath,
                                                      ascending: true)
        let providerNameDescriptor = NSSortDescriptor(key: providerNameKeyPath,
                                          ascending: true)

        return ResultsController<StorageShipmentTrackingProvider>(storageManager: storageManager,
                                                                       sectionNameKeyPath: groupNameKeyPath,
                                                                       matching: predicate,
                                                                       sortedBy: [providerGroupDescriptor, providerNameDescriptor])
    }()

    /// Closure to be executed in case there is an error fetching data
    ///
    var onError: ((Error) -> Void)?

    /// Convenience property to check if the data collection is empty
    ///
    var isListEmpty: Bool {
        return resultsController.fetchedObjects.count == 0
    }

    func shouldCreateCustomTracking(for groupName: String) -> Bool {
        return groupName == ShipmentStore.customGroupName
    }

    /// Designated initializer
    ///
    init(order: Order) {
        self.order = order
        fetchGroups()
    }

    /// Loads shipment tracking groups
    ///
    func fetchGroups() {
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            return
        }

        let orderID = order.orderID

        let loadGroupsAction = ShipmentAction.synchronizeShipmentTrackingProviders(siteID: siteID,
                                                                                   orderID: orderID) { [weak self] error in
            if let error = error {
                self?.handleError(error)
            }
        }

        StoresManager.shared.dispatch(loadGroupsAction)
    }

    /// Setup: Results Controller
    ///
    func configureResultsController(table: UITableView) {
        resultsController.startForwardingEvents(to: table)
        try? resultsController.performFetch()
        // Clearing filters (which nullfies the results controller predicate
        // seems to be necessary in order to get the Custom group to show up
        // I pressume there is a better way, but I can not find it.
        clearFilters()
    }

    /// Filter results by text
    ///
    func filter(by text: String) {
        let predicate = NSPredicate(format: "name CONTAINS[cd] %@", text)
        resultsController.predicate = predicate
    }

    /// Clear all filters
    ///
    func clearFilters() {
        resultsController.predicate = nil
    }

    private func handleError(_ error: Error) {
        onError?(error)
    }
}
