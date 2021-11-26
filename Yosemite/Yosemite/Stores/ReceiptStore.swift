import Storage
import Networking
import Hardware


// MARK: - ReceiptStore
//
public class ReceiptStore: Store {
    private let receiptPrinterService: PrinterService
    private let fileStorage: FileStorage

    private lazy var sharedDerivedStorage: StorageType = {
        storageManager.writerDerivedStorage
    }()

    private lazy var receiptNumberFormatter: NumberFormatter = {
        // We should use CurrencyFormatter instead for consistency
        let formatter = NumberFormatter()

        let fractionDigits = 2 // TODO - support non cent currencies like JPY - see #3948
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter
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
        case .print(let order, let info, let completion):
            print(order: order, parameters: info, completion: completion)
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
        let lineItems = generateLineItems(order: order)
        let cartTotals = generateCartTotals(order: order, parameters: parameters)
        let note = receiptOrderNote(order: order, removingHtml: removingHtml)

        return ReceiptContent(parameters: parameters,
                              lineItems: lineItems,
                              cartTotals: cartTotals,
                              orderNote: note)
    }

    private func receiptOrderNote(order: Order, removingHtml: Bool) -> String? {
        guard let orderNote = order.customerNote else {
            return nil
        }
        if removingHtml {
            // TODO: move this logic to the WooCommerce target, and then use String.removedHTMLTags extension function
            return orderNote.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        } else {
            return orderNote
        }
    }

    func generateLineItems(order: Order) -> [ReceiptLineItem] {
        order.items.map {item in
            var attributesText = ""
            if !item.attributes.isEmpty {
                attributesText.append(
                    item.attributes.map
                        {attr in
                            "\(attr.name) \(attr.value)".trimmingCharacters(in: .whitespaces)
                        }
                        .joined(separator: ", ")
                        .trimmingCharacters(in: .whitespaces)
                )
            }

            var title = item.name
            if !attributesText.isEmpty {
                title.append(". \(attributesText)")
            }
            return ReceiptLineItem(
                title: title,
                quantity: item.quantity.description,
                amount: item.subtotal
            )
        }
    }

    func generateCartTotals(order: Order, parameters: CardPresentReceiptParameters) -> [ReceiptTotalLine] {
        let subtotalLines = [
            productTotalLine(order: order),
            discountLine(order: order),
            lineIfNonZero(description: ReceiptContent.Localization.feesLineDescription, amount: feesLineAmount(fees: order.fees)),
            lineIfNonZero(description: ReceiptContent.Localization.shippingLineDescription, amount: order.shippingTotal),
            lineIfNonZero(description: ReceiptContent.Localization.totalTaxLineDescription, amount: order.totalTax)
        ].compactMap { $0 }
        let totalLine = [ReceiptTotalLine(description: ReceiptContent.Localization.amountPaidLineDescription,
                                         amount: parameters.formattedAmount)]

        return subtotalLines + totalLine
    }

    func productTotalLine(order: Order) -> ReceiptTotalLine {
        let lineItemsTotal = order.items.reduce(into: Decimal(0)) { result, item in
            result += NSDecimalNumber(apiAmount: item.subtotal).decimalValue
        }
        return ReceiptTotalLine(description: ReceiptContent.Localization.productTotalLineDescription,
                                amount: receiptNumberFormatter.string(from: lineItemsTotal as NSNumber) ?? "")
    }

    func discountLine(order: Order) -> ReceiptTotalLine? {
        let discountValue = NSDecimalNumber(apiAmount: order.discountTotal).decimalValue
        if discountValue == 0 && order.coupons.isEmpty {
            return nil
        }
        return ReceiptTotalLine(description: discountLineDescription(order: order),
                                amount: discountLineAmount(order: order, value: discountValue))
    }

    func discountLineDescription(order: Order) -> String {
        var couponCodes = ""
        if order.coupons.count > 0 {
            couponCodes = order.coupons.map {
                $0.code
            }
            .joined(separator: ", ")
            couponCodes = "(\(couponCodes))"
        }
        return String.localizedStringWithFormat(ReceiptContent.Localization.discountLineDescription, couponCodes)
    }

    func discountLineAmount(order: Order, value: Decimal) -> String {
        if value > 0 {
            return "-\(order.discountTotal)"
        } else {
            return order.discountTotal
        }
    }

    func feesLineAmount(fees: [OrderFeeLine]) -> String {
        let feeTotal = fees.reduce(into: Decimal(0)) { result, fee in
            result += NSDecimalNumber(apiAmount: fee.total).decimalValue
        }
        return receiptNumberFormatter.string(from: feeTotal as NSNumber) ?? ""
    }

    func lineIfNonZero(description: String, amount: String) -> ReceiptTotalLine? {
        guard NSDecimalNumber(apiAmount: amount).decimalValue != 0 else {
            return nil
        }
        return ReceiptTotalLine(description: description, amount: amount)
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
}

private extension NSDecimalNumber {
    convenience init(apiAmount: String) {
        self.init(string: apiAmount, locale: Locale(identifier: "en_US"))
    }
}
