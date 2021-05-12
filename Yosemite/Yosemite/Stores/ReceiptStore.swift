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

    }

    func saveReceipt(order: Order, parameters: CardPresentReceiptParameters) {
        let lineItems = order.items.map { ReceiptLineItem(title: $0.name, quantity: $0.quantity.description, amount: $0.price.stringValue)}

        let content = ReceiptContent(parameters: parameters, lineItems: lineItems)

        let renderer = ReceiptRenderer(content: content)

        let page = CGRect(x: 0, y: 0, width: 298, height: 500)
        renderer.setValue(page, forKey: "paperRect")
        renderer.setValue(page, forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)
        UIGraphicsBeginPDFPage()
        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()

        guard let outputURL = try? FileManager.default.url(for: .documentDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: false)
                .appendingPathComponent("order-id-\(order.orderID)-receipt")
                .appendingPathExtension("pdf")
            else {
            fatalError("Destination URL not created")
        }

        pdfData.write(to: outputURL, atomically: true)
        Swift.print("new receipt saved: open \(outputURL.path)") // command to open the generated file
    }
}
