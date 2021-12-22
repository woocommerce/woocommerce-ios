import Foundation
import Yosemite
import Combine

/// `ViewModel` to drive the content of the `SimplePaymentsSummary` view.
///
final class SimplePaymentsSummaryViewModel: ObservableObject {

    /// Initial amount to charge. Without taxes.
    ///
    let providedAmount: String

    /// Store tax percentage rate.
    ///
    let taxRate: String

    /// Tax amount to charge.
    ///
    let taxAmount: String

    /// Email of the costumer. To be used as the billing address email.
    ///
    @Published var email: String = ""

    /// Determines if taxes should be added to the provided amount.
    ///
    @Published var enableTaxes: Bool = false {
        didSet {
            analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowTaxesToggled(isOn: enableTaxes))
        }
    }

    /// Defines when to navigate to the payments method screen.
    ///
    @Published var navigateToPaymentMethods = false

    /// Defines if a loading indicator should be shown.
    ///
    @Published private(set) var showLoadingIndicator = false

    /// Total to charge. With or without taxes.
    ///
    var total: String {
        enableTaxes ? totalWithTaxes : providedAmount
    }

    /// Accessor for the note content of the `noteViewModel`
    ///
    var noteContent: String {
        noteViewModel.newNote
    }

    /// Disable view actions while a network request is being performed
    ///
    var disableViewActions: Bool {
        return showLoadingIndicator
    }

    /// Total to charge with taxes.
    ///
    private let totalWithTaxes: String

    /// Formatter to properly format the provided amount.
    ///
    private let currencyFormatter: CurrencyFormatter

    /// Store ID
    ///
    private let siteID: Int64

    /// Order ID to update.
    ///
    private let orderID: Int64

    /// Fee ID to update.
    ///
    private let feeID: Int64

    /// Transmits notice presentation intents.
    ///
    private let presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never>

    /// Stores Manager.
    ///
    private let stores: StoresManager

    /// Tracks analytics events.
    ///
    private let analytics: Analytics

    /// ViewModel for the edit order note view.
    ///
    lazy private(set) var noteViewModel = { SimplePaymentsNoteViewModel(analytics: analytics) }()

    init(providedAmount: String,
         totalWithTaxes: String,
         taxAmount: String,
         noteContent: String? = nil,
         siteID: Int64 = 0,
         orderID: Int64 = 0,
         feeID: Int64 = 0,
         presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never> = PassthroughSubject(),
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.orderID = orderID
        self.feeID = feeID
        self.presentNoticeSubject = presentNoticeSubject
        self.currencyFormatter = currencyFormatter
        self.stores = stores
        self.analytics = analytics
        self.providedAmount = currencyFormatter.formatAmount(providedAmount) ?? providedAmount
        self.totalWithTaxes = currencyFormatter.formatAmount(totalWithTaxes) ?? totalWithTaxes
        self.taxAmount = currencyFormatter.formatAmount(taxAmount) ?? taxAmount

        // rate_percentage = taxAmount / providedAmount * 100
        self.taxRate = {
            let amount = currencyFormatter.convertToDecimal(from: providedAmount)?.decimalValue ?? Decimal.zero
            let tax = currencyFormatter.convertToDecimal(from: taxAmount)?.decimalValue ?? Decimal.zero

            // Prevent dividing by zero
            guard amount > .zero else {
                return "0"
            }

            let rate = (tax / amount) * Decimal(100)
            return currencyFormatter.localize(rate) ?? "\(rate)"
        }()

        // Used mostly in previews
        if let noteContent = noteContent {
            noteViewModel = SimplePaymentsNoteViewModel(originalNote: noteContent)
        }
    }

    convenience init(order: Order,
                     providedAmount: String,
                     presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never> = PassthroughSubject(),
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                     stores: StoresManager = ServiceLocator.stores) {
        self.init(providedAmount: providedAmount,
                  totalWithTaxes: order.total,
                  taxAmount: order.totalTax,
                  siteID: order.siteID,
                  orderID: order.orderID,
                  feeID: order.fees.first?.feeID ?? 0,
                  presentNoticeSubject: presentNoticeSubject,
                  currencyFormatter: currencyFormatter,
                  stores: stores)
    }

    /// Sends a signal to reload the view. Needed when coming back from the `EditNote` view.
    ///
    func reloadContent() {
        objectWillChange.send()
    }

    /// Updates the order remotely with the information entered by the merchant.
    ///
    func updateOrder() {
        showLoadingIndicator = true

        // Clean any whitespace as it is not allowed by the remote endpoint
        email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        // Don't send empty emails as older WC stores can't handle them.
        let action = OrderAction.updateSimplePaymentsOrder(siteID: siteID,
                                                           orderID: orderID,
                                                           feeID: feeID,
                                                           amount: providedAmount,
                                                           taxable: enableTaxes,
                                                           orderNote: noteContent,
                                                           email: email.isEmpty ? nil : email) { [weak self] result in
            guard let self = self else { return }
            self.showLoadingIndicator = false

            switch result {
            case .success:
                self.navigateToPaymentMethods = true
            case .failure(let error):
                self.presentNoticeSubject.send(.error(Localization.updateError))
                self.analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowFailed(source: .summary))
                DDLogError("⛔️ Error updating simple payments order: \(error)")
            }
        }
        stores.dispatch(action)
    }

    /// Creates a view model for the `SimplePaymentsMethods` screen.
    ///
    func createMethodsViewModel() -> SimplePaymentsMethodsViewModel {
        SimplePaymentsMethodsViewModel(siteID: siteID,
                                       orderID: orderID,
                                       formattedTotal: total,
                                       presentNoticeSubject: presentNoticeSubject,
                                       stores: stores)
    }
}

// MARK: Constants
private extension SimplePaymentsSummaryViewModel {
    enum Localization {
        static let updateError = NSLocalizedString("There was an error updating the order",
                                                   comment: "Notice text after failing to update a simple payments order.")
    }
}
