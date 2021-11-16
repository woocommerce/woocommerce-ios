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

    init(providedAmount: String, noteContent: String? = nil) {
        self.providedAmount = providedAmount

        // TODO: Add taxes calculation
        self.total = providedAmount

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
