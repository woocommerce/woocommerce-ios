import Foundation
import Networking
import Storage

/// Implements `PaymentGatewayAccountAction` actions
///
public final class PaymentGatewayAccountStore: Store {

    /// For now, we only have one remote we support - the WCPay remote - to get an account
    /// In the future we'll want to allow this store to support other remotes
    ///
    private let remote: WCPayRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = WCPayRemote(network: network)
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
        guard let action = action as? PaymentGatewayAccountAction else {
            assertionFailure("PaymentGatewayAccountAction received an unsupported action")
            return
        }

        switch action {
        case let .loadAccounts(siteID, onCompletion):
            loadAccounts(siteID: siteID, onCompletion: onCompletion)
        }
    }
}

// MARK: Storage Methods
private extension PaymentGatewayAccountStore {

    func loadAccounts(siteID: Int64, onCompletion: @escaping (Result<[PaymentGatewayAccount], Error>) -> Void) {

        /// The only accounts we know about right now are WCPayAccounts
        ///
        remote.loadAccount(for: siteID) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success(let wcpayAccount):
                let account = wcpayAccount.toPaymentGatewayAccount(siteID: siteID)
                self.upsertStoredAccountInBackground(readonlyAccount: account)
                onCompletion(.success([account]))
                    return
            case .failure(let error):
                self.deleteStaleAccount(siteID: siteID, gatewayID: "woocommerce-payments") // TODO make a constant/enum
                onCompletion(.failure(error))
                return
            }

        }
    }

    func upsertStoredAccountInBackground(readonlyAccount: PaymentGatewayAccount) {
        let storage = storageManager.viewStorage
        let storageAccount = storage.loadPaymentGatewayAccount(siteID: readonlyAccount.siteID, gatewayID: readonlyAccount.gatewayID) ??
            storage.insertNewObject(ofType: Storage.PaymentGatewayAccount.self)

        storageAccount.update(with: readonlyAccount)
    }

    func deleteStaleAccount(siteID: Int64, gatewayID: String) {
        let storage = storageManager.viewStorage
        guard let storageAccount = storage.loadPaymentGatewayAccount(siteID: siteID, gatewayID: gatewayID) else {
            return
        }

        storage.deleteObject(storageAccount)
        storage.saveIfNeeded()
    }
}
