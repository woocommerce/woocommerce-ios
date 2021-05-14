import Storage
import Networking
import Hardware


// MARK: - ReceiptStore
//
public class ReceiptStore: Store {
    private let receiptPrinterService: PrinterService
    private let fileStorage: FileStorage

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, receiptPrinterService: PrinterService, fileStorage: FileStorage) {
        self.receiptPrinterService = receiptPrinterService
        self.fileStorage = fileStorage
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
        case .generateContent(let order, let info, let onContent):
            generateContent(order: order, parameters: info, onContent: onContent)
        case .loadReceipt(let order, let onCompletion):
            loadReceipt(order: order, onCompletion: onCompletion)
        case .saveReceipt(let order, let info):
            saveReceipt(order: order, parameters: info)
        }
    }
}


private extension ReceiptStore {
    func print(order: Order, parameters: CardPresentReceiptParameters) {
        let lineItems = order.items.map { ReceiptLineItem(title: $0.name, quantity: $0.quantity.description, amount: $0.price.stringValue)}

        let content = ReceiptContent(parameters: parameters, lineItems: lineItems)
        receiptPrinterService.printReceipt(content: content)
    }

    func generateContent(order: Order, parameters: CardPresentReceiptParameters, onContent: @escaping (String) -> Void) {
        let lineItems = order.items.map { ReceiptLineItem(title: $0.name, quantity: $0.quantity.description, amount: $0.price.stringValue)}

        let content = ReceiptContent(parameters: parameters, lineItems: lineItems)
        let renderer = ReceiptRenderer(content: content)
        onContent(renderer.htmlContent())
    }

    func loadReceipt(order: Order, onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> Void) {

        guard let outputURL = try? fileURL(order: order),
              FileManager.default.fileExists(atPath: outputURL.path) else {
            let error = ReceiptStoreError.fileNotFound
            onCompletion(.failure(error))
            return
        }

        guard let receiptContent: ReceiptContent = try? fileStorage.data(for: outputURL) else {
            DDLogWarn("⛔️ Unable to load receipt metadata for order: \(order.orderID)")
            let error = ReceiptStoreError.fileError
            onCompletion(.failure(error))

            return
        }

        onCompletion(.success(receiptContent.parameters))
    }

    func saveReceipt(order: Order, parameters: CardPresentReceiptParameters) {
        let lineItems = order.items.map { ReceiptLineItem(title: $0.name, quantity: $0.quantity.description, amount: $0.price.stringValue)}

        let content = ReceiptContent(parameters: parameters, lineItems: lineItems)

        guard let outputURL = try? fileURL(order: order) else {
            DDLogError("⛔️ Unable to create file for receipt for order id: \(order.orderID)")

            return
        }


        do {
            try fileStorage.write(content, to: outputURL)
            Swift.print("new receipt saved: open \(outputURL.path)") // command to open the generated file
        } catch {
            DDLogError("⛔️ Unable to save receipt for order id: \(order.orderID)")
        }
    }
}

private extension ReceiptStore {
    func fileURL(order: Order) throws -> URL {
        return try FileManager.default.url(for: .documentDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: false)
            .appendingPathComponent(fileName(order: order))
                .appendingPathExtension("plist")
    }

    func fileName(order: Order) -> String {
        "site-\(order.siteID)-order-id-\(order.orderID)-receipt"
    }
}

public enum ReceiptStoreError: Error {
    /// Signals that the file containing the receipt metadata does not exist
    case fileNotFound
    /// There was an error reading the content of the file containing the
    /// receipt metadata
    case fileError
}
