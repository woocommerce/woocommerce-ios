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
        case .printShippingLabel(let siteID, let shippingLabelID, let paperSize, let completion):
            printShippingLabel(siteID: siteID, shippingLabelID: shippingLabelID, paperSize: paperSize, completion: completion)
        }
    }
}

private extension ShippingLabelStore {
    func printShippingLabel(siteID: Int64,
                            shippingLabelID: Int64,
                            paperSize: ShippingLabelPaperSize,
                            completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void) {
        remote.printShippingLabel(siteID: siteID, shippingLabelID: shippingLabelID, paperSize: paperSize, completion: completion)
    }
}
