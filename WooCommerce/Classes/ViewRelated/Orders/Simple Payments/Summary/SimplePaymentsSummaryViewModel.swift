import Foundation

/// `ViewModel` to drive the content of the `SimplePaymentsSummary` view.
///
final class SimplePaymentsSummaryViewModel: ObservableObject {

    /// Initial amount to charge. Without taxes.
    ///
    let providedAmount: String

    /// Total to charge.
    ///
    let total: String

    /// Email of the costumer. To be used as the billing address email.
    ///
    @Published var email: String = ""

    /// Determines if taxes should be added to the provided amount.
    ///
    @Published var enableTaxes: Bool = false

    /// Accessor for the note content of the `noteViewModel`
    ///
    var noteContent: String {
        noteViewModel.newNote
    }

    /// ViewModel for the edit order note view.
    ///
    lazy private(set) var noteViewModel = SimplePaymentsNoteViewModel()

    /// Formatter to properly format the provided amount.
    ///
    private let currencyFormatter: CurrencyFormatter

    init(providedAmount: String,
         noteContent: String? = nil,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.currencyFormatter = currencyFormatter

        let formattedAmount = currencyFormatter.formatAmount(providedAmount) ?? providedAmount
        self.providedAmount = formattedAmount
        self.total = formattedAmount // TODO: Add taxes calculation

        // Used mostly in previews
        if let noteContent = noteContent {
            noteViewModel = SimplePaymentsNoteViewModel(originalNote: noteContent)
        }
    }

    /// Sends a signal to reload the view. Needed when coming back from the `EditNote` view.
    ///
    func reloadContent() {
        objectWillChange.send()
    }
}
