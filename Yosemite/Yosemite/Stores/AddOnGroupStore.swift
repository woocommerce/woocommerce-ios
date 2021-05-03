import Foundation
import Networking
import Storage

/// Implements actions from `AddOnGroupAction`
///
public final class AddOnGroupStore: Store {

    /// Remote source
    ///
    private let remote: AddOnGroupRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = AddOnGroupRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: AddOnGroupAction.self)
    }

    /// Receives and executes actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? AddOnGroupAction else {
            assertionFailure("ProductCategoryStore received an unsupported action")
            return
        }

        switch action {
        case let .synchronizeAddOnGroups(siteID, onCompletion):
            synchronizeAddOnGroups(siteID: siteID, onCompletion: onCompletion)
        }
    }
}

// MARK: Services
private extension AddOnGroupStore {
    /// Downloads and stores all add-on groups for a given `siteID`.
    ///
    func synchronizeAddOnGroups(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        remote.loadAddOnGroups(siteID: siteID) { [weak self] result in
            switch result {
            case .success(let groups):
                self?.upsertAddOnGroupsInBackground(siteID: siteID, readOnlyAddOnGroups: groups, onCompletion: onCompletion)
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }
}

// MARK: Storage
private extension AddOnGroupStore {
    /// Updates (OR Inserts) the provided ReadOnly `AddOnGroups` entities *in a background thread*.
    /// onCompletion will be called on the main thread!
    ///
    func upsertAddOnGroupsInBackground(siteID: Int64, readOnlyAddOnGroups: [AddOnGroup], onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let derivedStorage = storageManager.writerDerivedStorage
        derivedStorage.perform {
            self.upsertAddOnGroups(siteID: siteID, readOnlyAddOnGroups: readOnlyAddOnGroups, in: derivedStorage)
        }
        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async {
                onCompletion(.success(()))
            }
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly `AddOnGroups` entities into the Storage Layer.
    ///
    func upsertAddOnGroups(siteID: Int64, readOnlyAddOnGroups: [AddOnGroup], in storage: StorageType) {
        readOnlyAddOnGroups.forEach { readOnlyAddOnGroup in
            //  Get or create the stored add-on group
            let storedAddOnGroup: StorageAddOnGroup = {
                guard let existingGroup = storage.loadAddOnGroup(siteID: siteID, groupID: readOnlyAddOnGroup.groupID) else {
                    return storage.insertNewObject(ofType: StorageAddOnGroup.self)
                }
                return existingGroup
            }()

            // Update values and relationships
            storedAddOnGroup.update(with: readOnlyAddOnGroup)
            handleGroupAddOns(readOnlyGroup: readOnlyAddOnGroup, storageGroup: storedAddOnGroup, storage: storage)
        }

        // Delete stale groups
        let activeIDs = readOnlyAddOnGroups.map { $0.groupID }
        storage.deleteStaleAddOnGroups(siteID: siteID, activeGroupIDs: activeIDs)
    }

    /// Replaces the `storageGroup.addOns` with the new `readOnlyGroup.addOns`
    ///
    func handleGroupAddOns(readOnlyGroup: AddOnGroup, storageGroup: StorageAddOnGroup, storage: StorageType) {
        // Remove all previous addOns, they will be deleted as they have the `cascade` delete rule
        if let addOns = storageGroup.addOns {
            storageGroup.removeFromAddOns(addOns)
        }

        // Creates and adds `storageAddOns` from `readOnlyGroup.addOns`
        let storageAddOns = readOnlyGroup.addOns.map { readOnlyAddOn -> StorageProductAddOn in
            let storageAddOn = storage.insertNewObject(ofType: StorageProductAddOn.self)
            storageAddOn.update(with: readOnlyAddOn)
            handleAddOnsOptions(readOnlyAddOn: readOnlyAddOn, storageAddOn: storageAddOn, storage: storage)
            return storageAddOn
        }
        storageGroup.addToAddOns(NSOrderedSet(array: storageAddOns))
    }

    /// Replaces the `storageAddOn.options` with the new `readOnlyAddOn.options`
    ///
    func handleAddOnsOptions(readOnlyAddOn: ProductAddOn, storageAddOn: StorageProductAddOn, storage: StorageType) {
        // Remove all previous options, they will be deleted as they have the `cascade` delete rule
        if let options = storageAddOn.options {
            storageAddOn.removeFromOptions(options)
        }

        // Create and adds `storageAddOnsOptions` from `readOnlyAddOn.options`
        let storageAddOnsOptions = readOnlyAddOn.options.map { readOnlyAddOnOption -> StorageProductAddOnOption in
            let storageAddOnOption = storage.insertNewObject(ofType: StorageProductAddOnOption.self)
            storageAddOnOption.update(with: readOnlyAddOnOption)
            return storageAddOnOption
        }
        storageAddOn.addToOptions(NSOrderedSet(array: storageAddOnsOptions))
    }
}
