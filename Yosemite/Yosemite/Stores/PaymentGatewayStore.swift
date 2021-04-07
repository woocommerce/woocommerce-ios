import Foundation
import Networking
import Storage

/// Implements `PaymentGatewayAction` actions
///
public final class PaymentGatewayStore: Store {

    private let remote: PaymentGatewayRemote

    /// Shared private StorageType for use during then entire Orders sync process
    ///
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = PaymentGatewayRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: PaymentGatewayAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? PaymentGatewayAction else {
            assertionFailure("PaymentGatewayStore received an unsupported action")
            return
        }

        switch action {
        case let .synchronizePaymentGateways(siteID, onCompletion):
            synchronizePaymentGateways(siteID: siteID, onCompletion: onCompletion)
        }
    }
}

// MARK: Storage Methods
private extension PaymentGatewayStore {

    /// Loads and stores all payment gateways for the provided `siteID`
    func synchronizePaymentGateways(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        remote.loadAllPaymentGateways(siteID: siteID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let paymentGateways):
                self.upsertPaymentGatewaysInBackground(siteID: siteID, paymentGateways: paymentGateways) {
                    onCompletion(.success(()))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly Payment Gateways Entities
    /// *in a background thread*. `onCompletion` will be called on the main thread!
    ///
    func upsertPaymentGatewaysInBackground(siteID: Int64, paymentGateways: [PaymentGateway], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.upsertPaymentGateways(siteID: siteID, paymentGateways: paymentGateways)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly Payment Gateways Entities in the current thread
    ///
    func upsertPaymentGateways(siteID: Int64, paymentGateways: [PaymentGateway]) {
        let derivedStorage = sharedDerivedStorage
        for gateway in paymentGateways {
            let storageGateway = derivedStorage.loadPaymentGateway(siteID: gateway.siteID, gatewayID: gateway.gatewayID) ??
                derivedStorage.insertNewObject(ofType: Storage.PaymentGateway.self)
            storageGateway.update(with: gateway)
        }

        // Now, remove any objects that exist in storage but not in paymentGateways
        let storedGateways = derivedStorage.loadAllPaymentGateways(siteID: siteID)
        storedGateways.forEach { storedGateway in
            if !paymentGateways.contains(where: { $0.gatewayID == storedGateway.gatewayID }) {
                derivedStorage.deleteObject(storedGateway)
            }
        }
    }
}
