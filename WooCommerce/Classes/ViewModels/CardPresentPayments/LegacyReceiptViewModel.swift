import Combine
import MessageUI
import Yosemite
import WooFoundation

/// ViewModel supporting the locally-generated receipt preview.
final class LegacyReceiptViewModel {
    private let order: Order
    private let receipt: CardPresentReceiptParameters
    private let countryCode: CountryCode
    private let stores: StoresManager
    private let analytics: Analytics

    /// HTML content of a receipt.
    var content: AnyPublisher<String, Never> {
        $receiptContent.compactMap { $0 }.eraseToAnyPublisher()
    }

    @Published private var receiptContent: String?

    /// Initializer
    /// - Parameters:
    ///   - order: the order associated with the receipt
    ///   - receipt: the receipt metadata
    ///   - countryCode: the country code of the store
    ///   - stores: stores to dispatch receipt actions
    ///   - analytics: analytics to track receipt events
    init(order: Order,
         receipt: CardPresentReceiptParameters,
         countryCode: CountryCode,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.order = order
        self.receipt = receipt
        self.countryCode = countryCode
        self.stores = stores
        self.analytics = analytics
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
        Task { @MainActor in
            await ReceiptActionCoordinator.printReceipt(for: order,
                                                  params: receipt,
                                                  countryCode: countryCode,
                                                  cardReaderModel: nil,
                                                  stores: stores,
                                                  analytics: ServiceLocator.analytics)
        }
    }

    /// Returns a boolean that indicates whether email is supported for the app and device so that email UI is only displayed when it is supported.
    func canSendEmail() -> Bool {
        MFMailComposeViewController.canSendMail()
    }

    /// Called when the user initiates emailing a receipt. Returns a tuple of:
    /// - Observable of necessary data for the email form
    /// - Country code for analytics in the email form
    func emailReceiptTapped() -> AnyPublisher<(formData: CardPresentPaymentReceiptEmailCoordinator.EmailFormData, countryCode: CountryCode), Never> {
        analytics.track(event: .InPersonPayments
            .receiptEmailTapped(countryCode: countryCode,
                                cardReaderModel: nil,
                                source: .local))
        return content.map { .init(content: $0, order: self.order, storeName: self.stores.sessionManager.defaultSite?.name ?? "") }
            .map { (formData: $0, countryCode: self.countryCode) }
            .eraseToAnyPublisher()
    }
}
