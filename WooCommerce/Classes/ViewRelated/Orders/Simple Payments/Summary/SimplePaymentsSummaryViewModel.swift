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
    @Published var enableTaxes: Bool = false

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

    /// ViewModel for the edit order note view.
    ///
    lazy private(set) var noteViewModel = SimplePaymentsNoteViewModel()

    init(providedAmount: String,
         totalWithTaxes: String,
         taxAmount: String,
         noteContent: String? = nil,
         siteID: Int64 = 0,
         orderID: Int64 = 0,
         feeID: Int64 = 0,
         presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never> = PassthroughSubject(),
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.orderID = orderID
        self.feeID = feeID
        self.presentNoticeSubject = presentNoticeSubject
        self.currencyFormatter = currencyFormatter
        self.stores = stores
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
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                     stores: StoresManager = ServiceLocator.stores) {
        self.init(providedAmount: providedAmount,
                  totalWithTaxes: order.total,
                  taxAmount: order.totalTax,
                  siteID: order.siteID,
                  orderID: order.orderID,
                  feeID: order.fees.first?.feeID ?? 0,
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
        let action = OrderAction.updateSimplePaymentsOrder(siteID: siteID,
                                                           orderID: orderID,
                                                           feeID: feeID,
                                                           amount: providedAmount,
                                                           taxable: enableTaxes,
                                                           orderNote: noteContent,
                                                           email: email) { [weak self] result in
            guard let self = self else { return }
            self.showLoadingIndicator = false

            switch result {
            case .success:
                // TODO: Navigate to Payment Method
                // TODO: Analytics
                break
            case .failure:
                self.presentNoticeSubject.send(.error(Localization.updateError))
                // TODO: Analytics
                break
            }
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
