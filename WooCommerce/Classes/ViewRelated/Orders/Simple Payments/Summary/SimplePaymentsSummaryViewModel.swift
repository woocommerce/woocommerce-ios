import Foundation
import Yosemite

/// `ViewModel` to drive the content of the `SimplePaymentsSummary` view.
///
final class SimplePaymentsSummaryViewModel: ObservableObject {

    /// Initial amount to charge. Without taxes.
    ///
    let providedAmount: String

    /// Email of the costumer. To be used as the billing address email.
    ///
    @Published var email: String = ""

    /// Determines if taxes should be added to the provided amount.
    ///
    @Published var enableTaxes: Bool = false

    /// Total to charge. With or Without taxes.
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
         noteContent: String? = nil,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.currencyFormatter = currencyFormatter
        self.providedAmount = currencyFormatter.formatAmount(providedAmount) ?? providedAmount
        self.totalWithTaxes = currencyFormatter.formatAmount(totalWithTaxes) ?? providedAmount

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
                  currencyFormatter: currencyFormatter)
    }

    /// Sends a signal to reload the view. Needed when coming back from the `EditNote` view.
    ///
    func reloadContent() {
        objectWillChange.send()
    }
}
