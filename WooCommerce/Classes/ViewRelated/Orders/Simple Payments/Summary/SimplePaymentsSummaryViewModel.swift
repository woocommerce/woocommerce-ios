import Foundation
import Yosemite

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

    /// ViewModel for the edit order note view.
    ///
    lazy private(set) var noteViewModel = SimplePaymentsNoteViewModel()

    init(providedAmount: String,
         totalWithTaxes: String,
         taxAmount: String,
         noteContent: String? = nil,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.currencyFormatter = currencyFormatter
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
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.init(providedAmount: providedAmount,
                  totalWithTaxes: order.total,
                  taxAmount: order.totalTax,
                  currencyFormatter: currencyFormatter)
    }

    /// Sends a signal to reload the view. Needed when coming back from the `EditNote` view.
    ///
    func reloadContent() {
        objectWillChange.send()
    }
}
