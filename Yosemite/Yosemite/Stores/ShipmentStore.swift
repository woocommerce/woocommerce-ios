import Foundation
import Networking
import Storage


// MARK: - ShipmentStore
//
public class ShipmentStore: Store {

    /// Shared private StorageType for use during then entire ShipmentStore sync process
    ///
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ShipmentAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? ShipmentAction else {
            assertionFailure("ShipmentStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeShipmentTrackingData(let siteID, let orderID, let onCompletion):
            synchronizeShipmentTrackingData(siteID: siteID, orderID: orderID, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension ShipmentStore {

    func synchronizeShipmentTrackingData(siteID: Int, orderID: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = ShipmentsRemote(network: network)
        remote.loadShipmentTrackings(for: siteID, orderID: orderID) { [weak self] (shipmentTrackingData, error) in
            guard let readOnlyShipmentTrackingData = shipmentTrackingData else {
                onCompletion(error)
                return
            }

            self?.upsertShipmentTrackingDataInBackground(siteID: siteID, orderID: orderID, readOnlyShipmentTrackingData: readOnlyShipmentTrackingData) {
                onCompletion(nil)
            }
        }
    }

    func syncronizeShipmentTrackingProviderGroupsData(siteID: Int, orderID: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = ShipmentsRemote(network: network)
        remote.loadShipmentTrackingProviderGroups(for: siteID, orderID: orderID) { [weak self] (groups,error) in
            guard let readOnlyShipmentTrackingProviderGroups = groups else {
                onCompletion(error)
                return
            }

            self?.upsertShipmentTrackingProviderDataInBackground(siteID: siteID, orderID: orderID, readOnlyShipmentTrackingProviderGroups: readOnlyShipmentTrackingProviderGroups, onCompletion: {
                onCompletion(nil)
            })
        }
    }
}


// MARK: - Persistence
//
extension ShipmentStore {

    /// Updates (OR Inserts) the specified ReadOnly ShipmentTracking Entities into the Storage Layer *in a background thread*. onCompletion will be called
    /// on the main thread!
    ///
    func upsertShipmentTrackingDataInBackground(siteID: Int,
                                                orderID: Int,
                                                readOnlyShipmentTrackingData: [Networking.ShipmentTracking],
                                                onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            for readOnlyTracking in readOnlyShipmentTrackingData {
                let storageTracking = derivedStorage.loadShipmentTracking(siteID: readOnlyTracking.siteID, orderID: readOnlyTracking.orderID,
                    trackingID: readOnlyTracking.trackingID) ?? derivedStorage.insertNewObject(ofType: Storage.ShipmentTracking.self)
                storageTracking.update(with: readOnlyTracking)
            }

            // Now, remove any objects that exist in storage but not in readOnlyShipmentTrackingData
            if let storageTrackings = derivedStorage.loadShipmentTrackingList(siteID: siteID, orderID: orderID) {
                storageTrackings.forEach({ storageTracking in
                    if readOnlyShipmentTrackingData.first(where: { $0.trackingID == storageTracking.trackingID } ) == nil {
                        derivedStorage.deleteObject(storageTracking)
                    }
                })
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    func upsertShipmentTrackingProviderDataInBackground(siteID: Int, orderID: Int, readOnlyShipmentTrackingProviderGroups: [Networking.ShipmentTrackingProviderGroup], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage

        derivedStorage.perform {
            for readOnlyTrackingGroup in readOnlyShipmentTrackingProviderGroups {
                let storageTracking = derivedStorage.loadShipmentTrackingProviderGroup(siteID: siteID, providerGroupName: readOnlyTrackingGroup.name) ?? derivedStorage.insertNewObject(ofType: Storage.ShipmentTrackingProviderGroup.self)
                storageTracking.update(with: readOnlyTrackingGroup)
            }

            // Now, remove any objects that exist in storage but not in readOnlyShipmentTrackingProviderGroups
            if let storageTrackingGroups = derivedStorage.loadShipmentTrackingProviderGroupList(siteID: siteID) {
                storageTrackingGroups.forEach({ storageTrackingGroup in
                    if readOnlyShipmentTrackingProviderGroups.first(where: { $0.name == storageTrackingGroup.name } ) == nil {
                        derivedStorage.deleteObject(storageTrackingGroup)
                    }
                })
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}
