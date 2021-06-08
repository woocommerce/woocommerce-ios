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

    func loadAccounts(siteID: Int64, onCompletion: (Result<[PaymentGatewayAccount], Error>) -> Void) {
        // Make it work similar to RefundStore.swift retrieveRefunds
        // hits up the WCPayRemote to get the account
        // deletes the stored account if it isn’t found
        // converts the WCPayAccount to a PaymentGatewayAccount (using the extension above)
        // upserts the PaymentGatewayAccount account if it is found
    }

    // Add deleteStoredAccounts to it similar to deleteStaleRefunds
    // Add upsertStoredAccountsInBackground to it similar to upsertStoredRefundsInBackground
}
