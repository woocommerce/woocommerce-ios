import Storage
import Networking
import Hardware


// MARK: - ReceiptStore
//
public class ReceiptStore: Store {
    private let receiptPrinterService: PrinterService

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, receiptPrinterService: PrinterService) {
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
        case .print(let order, let info):
            print(order: order, parameters: info)
        }
    }
}


private extension ReceiptStore {
    func print(order: Order, parameters: CardPresentReceiptParameters) {
        let lineItems = order.items.map { ReceiptLineItem(title: $0.name)}

        let content = ReceiptContent(parameters: parameters, lineItems: lineItems)
        receiptPrinterService.printReceipt(content: content)
    }
}
