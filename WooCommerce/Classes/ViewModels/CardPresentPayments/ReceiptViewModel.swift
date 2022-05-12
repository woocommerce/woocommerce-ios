import Combine
import Yosemite

/// ViewModel supporting the receipt preview.
final class ReceiptViewModel {
    private let order: Order
    private let receipt: CardPresentReceiptParameters
    private let countryCode: String
    private let stores: StoresManager

    /// HTML content of a receipt.
    var content: AnyPublisher<String, Never> {
        $receiptContent.compactMap { $0 }.eraseToAnyPublisher()
    }

    /// Necessary data for emailing a receipt.
    var emailFormData: AnyPublisher<CardPresentPaymentReceiptEmailCoordinator.EmailFormData, Never> {
        content.map { .init(content: $0, order: self.order, storeName: self.stores.sessionManager.defaultSite?.name ?? "") }
            .eraseToAnyPublisher()
    }

    @Published private var receiptContent: String?

    /// Initializer
    /// - Parameters:
    ///   - order: the order associated with the receipt
    ///   - receipt: the receipt metadata
    ///   - countryCode: the country code of the store
    ///   - stores: stores to dispatch receipt actions
    init(order: Order, receipt: CardPresentReceiptParameters, countryCode: String, stores: StoresManager = ServiceLocator.stores) {
        self.order = order
        self.receipt = receipt
        self.countryCode = countryCode
        self.stores = stores
    }


    /// Generates the receipt content and updates `receiptContent` subject.
    func generateContent() {
        let action = ReceiptAction.generateContent(order: order, parameters: receipt) { [weak self] receiptContent in
            self?.receiptContent = receiptContent
        }
        stores.dispatch(action)
    }


    /// Prints the receipt
    func printReceipt() {
        ReceiptActionCoordinator.printReceipt(for: order,
                                              params: receipt,
                                              countryCode: countryCode,
                                              cardReaderModel: nil,
                                              stores: stores,
                                              analytics: ServiceLocator.analytics)
    }
}
