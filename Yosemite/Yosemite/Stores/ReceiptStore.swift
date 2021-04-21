import Storage
import Networking
import Hardware


// MARK: - ReceiptStore
//
public class ReceiptStore: Store {
    private let receiptPrinterService: ReceiptPrinterService

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, receiptPrinterService: ReceiptPrinterService) {
        self.receiptPrinterService = receiptPrinterService
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ReceiptAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? ReceiptAction else {
            assertionFailure("ReceiptStore received an unsupported action")
            return
        }

        switch action {
//        case .createRefund(let siteID, let orderID, let refund, let onCompletion):
//            createRefund(siteID: siteID, orderID: orderID, refund: refund, onCompletion: onCompletion)
//        case .retrieveRefund(let siteID, let orderID, let refundID, let onCompletion):
//            retrieveRefund(siteID: siteID, orderID: orderID, refundID: refundID, onCompletion: onCompletion)
//        case .retrieveRefunds(let siteID, let orderID, let refundIDs, let deleteStaleRefunds, let onCompletion):
//            retrieveRefunds(siteID: siteID, orderID: orderID, refundIDs: refundIDs, deleteStaleRefunds: deleteStaleRefunds, onCompletion: onCompletion)
//        case .synchronizeRefunds(let siteID, let orderID, let pageNumber, let pageSize, let onCompletion):
//            synchronizeRefunds(siteID: siteID, orderID: orderID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
//        case .resetStoredRefunds(let onCompletion):
//            resetStoredRefunds(onCompletion: onCompletion)
        }
    }
}
