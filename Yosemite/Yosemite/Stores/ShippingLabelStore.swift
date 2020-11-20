import Foundation
import Networking
import Storage

/// Implements `ShippingLabelAction` actions
///
public final class ShippingLabelStore: Store {
    private let remote: ShippingLabelRemoteProtocol

    /// Shared private StorageType for use during then entire Orders sync process
    ///
    private lazy var sharedDerivedStorage: StorageType = {
        storageManager.newDerivedStorage()
    }()

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = ShippingLabelRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: ShippingLabelRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ShippingLabelAction.self)
    }

    /// Receives and executes Actions.
    override public func onAction(_ action: Action) {
        guard let action = action as? ShippingLabelAction else {
            assertionFailure("ShippingLabelStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeShippingLabels(let siteID, let orderID, let completion):
            synchronizeShippingLabels(siteID: siteID, orderID: orderID, completion: completion)
        case .printShippingLabel(let siteID, let shippingLabelID, let paperSize, let completion):
            printShippingLabel(siteID: siteID, shippingLabelID: shippingLabelID, paperSize: paperSize, completion: completion)
        }
    }
}

private extension ShippingLabelStore {
    func synchronizeShippingLabels(siteID: Int64, orderID: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        remote.loadShippingLabels(siteID: siteID, orderID: orderID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                self.upsertShippingLabelsAndSettingsInBackground(siteID: siteID,
                                                                 orderID: orderID,
                                                                 shippingLabels: response.shippingLabels,
                                                                 settings: response.settings) {
                    completion(.success(()))
                }
            }
        }
    }

    func printShippingLabel(siteID: Int64,
                            shippingLabelID: Int64,
                            paperSize: ShippingLabelPaperSize,
                            completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void) {
        remote.printShippingLabel(siteID: siteID, shippingLabelID: shippingLabelID, paperSize: paperSize, completion: completion)
    }
}

private extension ShippingLabelStore {
    /// Updates/inserts the specified readonly shipping label & settings entities *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    func upsertShippingLabelsAndSettingsInBackground(siteID: Int64,
                                                     orderID: Int64,
                                                     shippingLabels: [ShippingLabel],
                                                     settings: ShippingLabelSettings,
                                                     onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            guard let self = self else { return }
            guard let order = derivedStorage.loadOrder(siteID: siteID, orderID: orderID) else {
                return
            }
            guard shippingLabels.isEmpty == false else {
                return
            }
            self.upsertShippingLabels(siteID: siteID, orderID: orderID, shippingLabels: shippingLabels, storageOrder: order)
            self.upsertShippingLabelSettings(siteID: siteID, orderID: orderID, settings: settings, storageOrder: order)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates/inserts the specified readonly ShippingLabel entities in the current thread.
    func upsertShippingLabels(siteID: Int64, orderID: Int64, shippingLabels: [ShippingLabel], storageOrder: StorageOrder) {
        let derivedStorage = sharedDerivedStorage

        for shippingLabel in shippingLabels {
            let storageShippingLabel = derivedStorage.loadShippingLabel(siteID: shippingLabel.siteID,
                                                                        orderID: shippingLabel.orderID,
                                                                        shippingLabelID: shippingLabel.shippingLabelID) ??
                derivedStorage.insertNewObject(ofType: Storage.ShippingLabel.self)
            storageShippingLabel.update(with: shippingLabel)
            storageShippingLabel.order = storageOrder

            if let refund = shippingLabel.refund {
                let storageRefund = storageShippingLabel.refund ?? derivedStorage.insertNewObject(ofType: Storage.ShippingLabelRefund.self)
                storageRefund.update(with: refund)
                storageShippingLabel.refund = storageRefund
            } else {
                storageShippingLabel.refund = nil
            }

            let originAddress = storageShippingLabel.originAddress ?? derivedStorage.insertNewObject(ofType: Storage.ShippingLabelAddress.self)
            originAddress.update(with: shippingLabel.originAddress)
            storageShippingLabel.originAddress = originAddress

            let destinationAddress = storageShippingLabel.destinationAddress ?? derivedStorage.insertNewObject(ofType: Storage.ShippingLabelAddress.self)
            destinationAddress.update(with: shippingLabel.destinationAddress)
            storageShippingLabel.destinationAddress = destinationAddress
        }

        // Now, remove any objects that exist in storage but not in shippingLabels
        let shippingLabelIDs = shippingLabels.map(\.shippingLabelID)
        derivedStorage.loadAllShippingLabels(siteID: siteID, orderID: orderID).filter {
            !shippingLabelIDs.contains($0.shippingLabelID)
        }.forEach {
            derivedStorage.deleteObject($0)
        }
    }

    /// Updates/inserts the specified readonly ShippingLabelSettings entity in the current thread.
    func upsertShippingLabelSettings(siteID: Int64, orderID: Int64, settings: ShippingLabelSettings, storageOrder: StorageOrder) {
        let derivedStorage = sharedDerivedStorage
        let storageSettings = derivedStorage.loadShippingLabelSettings(siteID: siteID, orderID: orderID) ??
            derivedStorage.insertNewObject(ofType: Storage.ShippingLabelSettings.self)
        storageSettings.update(with: settings)
        storageSettings.order = storageOrder
    }
}
