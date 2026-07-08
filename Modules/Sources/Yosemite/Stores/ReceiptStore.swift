import Foundation
import Storage
import Networking
import Hardware
import WooFoundation


// MARK: - ReceiptStore
//
public class ReceiptStore: Store {
    private let receiptPrinterService: PrinterService
    private let fileStorage: FileStorage
    private let remote: ReceiptRemote

    private lazy var currencyFormatter: CurrencyFormatter = {
        CurrencyFormatter(currencySettings: CurrencySettings())
    }()

    private lazy var contentAssembler = ReceiptContentAssembler(currencyFormatter: currencyFormatter)

    public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, receiptPrinterService: PrinterService, fileStorage: FileStorage) {
        self.receiptPrinterService = receiptPrinterService
        self.fileStorage = fileStorage
        self.remote = ReceiptRemote(network: network)
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
        case .print(let order, let info, let completion):
            print(order: order, parameters: info, completion: completion)
        case .generateContent(let order, let info, let onContent):
            generateContent(order: order, parameters: info, onContent: onContent)
        case .loadReceipt(let order, let onCompletion):
            loadReceipt(order: order, onCompletion: onCompletion)
        case .saveReceipt(let order, let info):
            saveReceipt(order: order, parameters: info)
        case .retrieveReceipt(order: let order, onCompletion: let onCompletion):
            retrieveReceipt(order: order, onCompletion: onCompletion)
        case let .sendReceipt(order, email, onCompletion):
            sendReceipt(order: order, email: email, onCompletion: onCompletion)
        }
    }
}


private extension ReceiptStore {
    func retrieveReceipt(order: Order, onCompletion: @escaping (Result<Receipt, Error>) -> Void) {
        remote.retrieveReceipt(siteID: order.siteID,
                               orderID: order.orderID) { result in
            switch result {
            case let .success(receipt):
                onCompletion(.success(receipt))
            case let .failure(error):
                onCompletion(.failure(error))
            }
        }
    }

    func print(order: Order, parameters: CardPresentReceiptParameters, completion: @escaping (PrintingResult) -> Void) {
        let content = generateReceiptContent(order: order, parameters: parameters, removingHtml: true)
        receiptPrinterService.printReceipt(content: content, completion: completion)
    }

    func generateContent(order: Order, parameters: CardPresentReceiptParameters, onContent: @escaping (String) -> Void) {
        let content = generateReceiptContent(order: order, parameters: parameters)
        let renderer = ReceiptRenderer(content: content)
        onContent(renderer.htmlContent())
    }

    func generateReceiptContent(order: Order, parameters: CardPresentReceiptParameters, removingHtml: Bool = false) -> ReceiptContent {
        contentAssembler.makeContent(order: order, parameters: parameters, removingHtml: removingHtml)
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
        let content = generateReceiptContent(order: order, parameters: parameters)

        guard let outputURL = try? fileURL(order: order) else {
            DDLogError("⛔️ Unable to create file for receipt for order id: \(order.orderID)")

            return
        }


        do {
            try fileStorage.write(content, to: outputURL)
        } catch {
            DDLogError("⛔️ Unable to save receipt for order id: \(order.orderID)")
        }
    }

    /// Sends the receipt for the order to the provided email address if customer email hasn't been set yet.
    /// Updates the billing address of the order to the provided email address and triggers the sending of the receipt.
    /// - Parameters:
    ///  - order: The order for which the receipt is being sent.
    ///  - email: The email address to which the receipt is being sent.
    ///  - onCompletion: The completion block to call when the operation is complete.
    ///
    func sendReceipt(order: Order, email: String, onCompletion: @escaping (Result<Order, Error>) -> Void) {
        guard order.billingAddress?.email == nil || order.billingAddress?.email?.isEmpty == true else {
            onCompletion(.failure(ReceiptStoreError.customerEmailAlreadySet))
            return
        }

        let updatedBillingAddress = order.billingAddress?.copy(email: email) ?? Address(firstName: "",
                                                                                        lastName: "",
                                                                                        company: nil,
                                                                                        address1: "",
                                                                                        address2: nil,
                                                                                        city: "",
                                                                                        state: "",
                                                                                        postcode: "",
                                                                                        country: "",
                                                                                        phone: nil,
                                                                                        email: email)
        let orderToUpdate = order.copy(billingAddress: updatedBillingAddress)

        let action = OrderAction.updateOrder(siteID: order.siteID, order: orderToUpdate, giftCard: nil, fields: [.billingAddress]) { result in
            switch result {
            case let .success(updatedOrder):
                Task { [weak self] in
                    guard let self else {
                        onCompletion(.failure(ReceiptStoreError.storeDeallocated))
                        return
                    }

                    do {
                        try await remote.sendReceipt(siteID: order.siteID, orderID: order.orderID)
                        onCompletion(.success(updatedOrder))
                    } catch {
                        onCompletion(.failure(error))
                    }
                }
            case let .failure(error):
                onCompletion(.failure(error))
            }
        }

        dispatcher.dispatch(action)
    }
}

private extension ReceiptStore {
    func fileURL(order: Order) throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
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

    /// Store has been unexpectedly deallocated
    case storeDeallocated

    /// Customer email has already been set and receipt cannot be sent
    case customerEmailAlreadySet
}
