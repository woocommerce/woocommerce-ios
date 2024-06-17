import Foundation
import Yosemite
import Combine
import Experiments
import WooFoundation
import class WordPressShared.EmailFormatValidator

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

        /// Creates a `TaxLine` with zero tax percentage and tax amount
        ///
        static func createZeroValueTaxLine(currencyFormatter: CurrencyFormatter) -> TaxLine {
            TaxLine(id: 0,
                    title: "\(Localization.tax) (0.00%)",
                    value: currencyFormatter.formatAmount(Decimal.zero) ?? "\(Decimal.zero)")
        }
    }

    /// Initial amount to charge. Without taxes.
    ///
    let providedAmount: String

    /// Store tax lines.
    ///
    let taxLines: [TaxLine]

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

    /// Total to charge with taxes.
    ///
    private let totalWithTaxes: String

    /// Formatter to properly format the provided amount.
    ///
    private let currencyFormatter: CurrencyFormatter

    /// Store country code for analytics.
    private let countryCode: CountryCode

    /// Store Currency Settings
    ///
    private let currencySettings: CurrencySettings

    /// Store ID
    ///
    private let siteID: Int64

    /// Order ID to update.
    ///
    private let orderID: Int64

    /// Order payment URL.
    /// Optional because older stores `(< 6.4)` don't provide this information.
    ///
    private let paymentLink: URL?

    /// Fee ID to update.
    ///
    private let feeID: Int64

    /// Transmits notice presentation intents.
    ///
    private let presentNoticeSubject: PassthroughSubject<PaymentMethodsNotice, Never>

    /// Stores Manager.
    ///
    private let stores: StoresManager

    /// Tracks analytics events.
    ///
    private let analytics: Analytics
    private let flow: WooAnalyticsEvent.PaymentsFlow.Flow

    /// ViewModel for the edit order note view.
    ///
    lazy private(set) var noteViewModel = { SimplePaymentsNoteViewModel(analytics: analytics) }()

    init(providedAmount: String,
         totalWithTaxes: String,
         taxLines: [TaxLine],
         noteContent: String? = nil,
         siteID: Int64 = 0,
         orderID: Int64 = 0,
         paymentLink: URL? = nil,
         feeID: Int64 = 0,
         presentNoticeSubject: PassthroughSubject<PaymentMethodsNotice, Never> = PassthroughSubject(),
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         stores: StoresManager = ServiceLocator.stores,
         countryCode: CountryCode = SiteAddress().countryCode,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         analyticsFlow: WooAnalyticsEvent.PaymentsFlow.Flow = .simplePayment) {
        self.siteID = siteID
        self.orderID = orderID
        self.paymentLink = paymentLink
        self.feeID = feeID
        self.presentNoticeSubject = presentNoticeSubject
        self.currencyFormatter = currencyFormatter
        self.stores = stores
        self.countryCode = countryCode
        self.currencySettings = currencySettings
        self.analytics = analytics
        self.flow = analyticsFlow
        self.providedAmount = currencyFormatter.formatAmount(providedAmount) ?? providedAmount
        self.totalWithTaxes = currencyFormatter.formatAmount(totalWithTaxes) ?? totalWithTaxes

        if taxLines.isNotEmpty {
            self.taxLines = taxLines
        } else {
            // Assigning `taxLines` with a zero value `TaxLine` to represent that there are no taxes configured in `wp-admin`.
            self.taxLines = [TaxLine.createZeroValueTaxLine(currencyFormatter: currencyFormatter)]
        }

        // Used mostly in previews
        if let noteContent = noteContent {
            noteViewModel = SimplePaymentsNoteViewModel(originalNote: noteContent)
        }

        // Loads the latest stored taxes toggle state.
        loadCurrentTaxesToggleState()
    }

    convenience init(order: Order,
                     providedAmount: String,
                     presentNoticeSubject: PassthroughSubject<PaymentMethodsNotice, Never> = PassthroughSubject(),
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                     stores: StoresManager = ServiceLocator.stores,
                     analyticsFlow: WooAnalyticsEvent.PaymentsFlow.Flow = .simplePayment) {

        // Generate `TaxLine`s to represent `taxes` inside `View`.
        let taxLines = order.taxes.map({
            TaxLine(orderTaxLine: $0,
                    currencyFormatter: currencyFormatter)
        })

        self.init(providedAmount: providedAmount,
                  totalWithTaxes: order.total,
                  taxLines: taxLines,
                  siteID: order.siteID,
                  orderID: order.orderID,
                  paymentLink: order.paymentURL,
                  feeID: order.fees.first?.feeID ?? 0,
                  presentNoticeSubject: presentNoticeSubject,
                  currencyFormatter: currencyFormatter,
                  stores: stores,
                  analyticsFlow: analyticsFlow)
    }

    /// Sends a signal to reload the view. Needed when coming back from the `EditNote` view.
    ///
    func reloadContent() {
        objectWillChange.send()
    }

    /// Updates the order remotely with the information entered by the merchant.
    ///
    func updateOrder() {
        // Clean any whitespace as it is not allowed by the remote endpoint
        email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        // Perform local email validation
        guard email.isEmpty || EmailFormatValidator.validate(string: email) else {
            return presentNoticeSubject.send(.error(Localization.invalidEmail))
        }

        showLoadingIndicator = true

        // Don't send empty emails as older WC stores can't handle them.
        let action = OrderAction.updateSimplePaymentsOrder(siteID: siteID,
                                                           orderID: orderID,
                                                           feeID: feeID,
                                                           status: .pending, // Force .pending status to properly generate the payment link in the next screen.
                                                           amount: removeCurrencySymbolFromAmount(providedAmount),
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
                self.analytics.track(event: WooAnalyticsEvent.PaymentsFlow.paymentsFlowFailed(flow: self.flow,
                                                                                              source: .summary,
                                                                                              country: countryCode,
                                                                                              currency: currencySettings.currencyCode.rawValue))
                DDLogError("⛔️ Error updating simple payments order: \(error)")
            }
        }
        stores.dispatch(action)
    }

    /// Creates a view model for the `SimplePaymentsMethods` screen.
    ///
    @MainActor
    func createMethodsViewModel() -> PaymentMethodsViewModel {
        PaymentMethodsViewModel(siteID: siteID,
                                orderID: orderID,
                                paymentLink: paymentLink,
                                formattedTotal: total,
                                flow: flow,
                                dependencies: .init(
                                    presentNoticeSubject: presentNoticeSubject,
                                    stores: stores))
    }
}

// MARK: Helpers
private extension SimplePaymentsSummaryViewModel {
    /// Strips the currency symbol from the formatted amount
    ///
    func removeCurrencySymbolFromAmount(_ amount: String) -> String {
        let minusSign: String = NumberFormatter().minusSign

        let currencyCode = currencySettings.currencyCode
        let currencySymbol = currencySettings.symbol(from: currencyCode)
        let amountWithoutSymbol = amount.replacingOccurrences(of: currencySymbol, with: "")

        let formattedAmount = currencyFormatter.formatCurrency(using: amountWithoutSymbol,
                                                               currencyPosition: currencySettings.currencyPosition,
                                                               currencySymbol: "",
                                                               isNegative: providedAmount.hasPrefix(minusSign))
        return formattedAmount
    }
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
        static let invalidEmail = NSLocalizedString("Please enter a valid email address.", comment: "Notice text when the merchant enters an invalid email")
        static let tax = NSLocalizedString("Tax",
                                             comment: "Tax label for the tax detail row.")

    }
}
