import Foundation
import UIKit
import Yosemite

final class ShippingProvidersViewModel {
    private let orderID: Int
    private(set) var groups = [ShipmentTrackingProviderGroup]()

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

    init(orderID: Int) {
        self.orderID = orderID
        fetchGroups()
    }

    private func fetchGroups() {
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            return
        }

        let loadGroupsAction = ShipmentAction.synchronizeShipmentTrackingProviders(siteID: siteID, orderID: orderID) { [weak self] error in
            if let error = error {
                self?.presentNotice(error)
            }
        }

        StoresManager.shared.dispatch(loadGroupsAction)
    }

    /// Setup: Results Controller
    ///
    func configureResultsController(table: UITableView, completion: @escaping ()-> Void) {
        resultsController.onDidChangeContent = { [weak self] in
            guard let `self` = self else {
                return
            }

            self.groups = self.resultsController.fetchedObjects
            completion()
        }

        resultsController.onDidResetContent = { [weak self] in
            guard let `self` = self else {
                return
            }

            self.groups = self.resultsController.fetchedObjects
            completion()
        }

        resultsController.startForwardingEvents(to: table)
        try? resultsController.performFetch()
    }

    private func presentNotice(_ error: Error) {
        print("==== present error notice ====")
    }
}
