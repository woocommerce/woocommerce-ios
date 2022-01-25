import Foundation
import Yosemite
import Combine
import Experiments

/// `ViewModel` to drive the content of the `SimplePaymentsSummary` view.
///
final class SimplePaymentsSummaryViewModel: ObservableObject {

    /// Wraps the `Order`'s tax breakup (`tax_lines`) information
    ///
    /// `Identifiable` conformance added for SwiftUI purpose
    ///
    struct TaxLine: Identifiable {
        /// `taxID` of `OrderTaxLine`
        ///
        let id: Int64

        /// Tax label appended with tax percentage
        ///
        let title: String

        /// Tax amount
        ///
        let value: String

        init(id: Int64,
             title: String,
             value: String) {
            self.id = id
            self.title = title
            self.value = value
        }

        /// For initializing TaxLine from `OrderTaxLine`
        ///
        init(orderTaxLine: OrderTaxLine,
             currencyFormatter: CurrencyFormatter) {
            id = orderTaxLine.taxID
            title = "\(orderTaxLine.label) (\(orderTaxLine.ratePercent)%)"
            value = currencyFormatter.formatAmount(orderTaxLine.totalTax) ?? orderTaxLine.totalTax
        }
    }

    /// Initial amount to charge. Without taxes.
    ///
    let providedAmount: String

    /// Store tax percentage rate.
    ///
    let taxRate: String

    /// Store tax lines.
    ///
    let taxLines: [TaxLine]

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
            storeTaxesToggleState()
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

    /// Show tax break up using `tax_lines` in summary
    ///
    var showTaxBreakup: Bool {
        featureFlagService.isFeatureFlagEnabled(.taxLinesInSimplePayments)
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

    /// Order Key. Needed to generate the payment link in `PaymentMethodViewModel`
    ///
    private let orderKey: String

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

    /// FeatureFlagService to check `tax_lines` related flag (`taxLinesInSimplePayments`)
    ///
    private let featureFlagService: FeatureFlagService

    init(providedAmount: String,
         totalWithTaxes: String,
         taxAmount: String,
         taxLines: [TaxLine],
         noteContent: String? = nil,
         siteID: Int64 = 0,
         orderID: Int64 = 0,
         orderKey: String = "",
         feeID: Int64 = 0,
         presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never> = PassthroughSubject(),
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteID = siteID
        self.orderID = orderID
        self.orderKey = orderKey
        self.feeID = feeID
        self.presentNoticeSubject = presentNoticeSubject
        self.currencyFormatter = currencyFormatter
        self.stores = stores
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        self.providedAmount = currencyFormatter.formatAmount(providedAmount) ?? providedAmount
        self.totalWithTaxes = currencyFormatter.formatAmount(totalWithTaxes) ?? totalWithTaxes
        self.taxAmount = currencyFormatter.formatAmount(taxAmount) ?? taxAmount
        self.taxLines = taxLines

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

        // Loads the latest stored taxes toggle state.
        loadCurrentTaxesToggleState()
    }

    convenience init(order: Order,
                     providedAmount: String,
                     presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never> = PassthroughSubject(),
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                     stores: StoresManager = ServiceLocator.stores) {

        // Generate `TaxLine`s to represent `taxes` inside `View`.
        let taxLines = order.taxes.map({
            TaxLine(orderTaxLine: $0,
                    currencyFormatter: currencyFormatter)
        })

        self.init(providedAmount: providedAmount,
                  totalWithTaxes: order.total,
                  taxAmount: order.totalTax,
                  taxLines: taxLines,
                  siteID: order.siteID,
                  orderID: order.orderID,
                  orderKey: order.orderKey,
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
                                       orderKey: orderKey,
                                       formattedTotal: total,
                                       presentNoticeSubject: presentNoticeSubject,
                                       stores: stores)
    }
}

// MARK: Helpers
private extension SimplePaymentsSummaryViewModel {
    /// Loads the current taxes toggle state.
    ///
    func loadCurrentTaxesToggleState() {
        let action = AppSettingsAction.getSimplePaymentsTaxesToggleState(siteID: siteID) { result in
            guard case .success(let isOn) = result else {
                return
            }
            self.enableTaxes = isOn
        }
        stores.dispatch(action)
    }

    /// Stores the current taxes toggle state for later query.
    ///
    func storeTaxesToggleState() {
        let action = AppSettingsAction.setSimplePaymentsTaxesToggleState(siteID: siteID, isOn: enableTaxes) { _ in
            // No op
        }
        stores.dispatch(action)
    }
}

// MARK: Constants
private extension SimplePaymentsSummaryViewModel {
    enum Localization {
        static let updateError = NSLocalizedString("There was an error updating the order",
                                                   comment: "Notice text after failing to update a simple payments order.")
    }
}
