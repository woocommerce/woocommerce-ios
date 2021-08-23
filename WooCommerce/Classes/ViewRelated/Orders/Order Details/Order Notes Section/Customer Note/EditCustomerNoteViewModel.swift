import Foundation
import Yosemite

/// View Model for the Edit Customer Note screen
///
final class EditCustomerNoteViewModel: ObservableObject {

    /// Original content of the order customer provided note
    ///
    private let originalNote: String

    /// New content to submit.
    /// Binding property modified at the view level.
    ///
    @Published var newNote: String

    /// True when the loading spinner should be shown.
    /// Like when performing a network operation
    ///
    @Published private(set) var showLoadingIndicator: Bool = false

    /// True when there are changes to the `initialNote`. False otherwise.
    ///
    var doneEnabled: Bool {
        originalNote != newNote
    }

    init(order: Order) {
        self.originalNote = order.customerNote ?? ""
        self.newNote = originalNote
    }

    /// Member wise initializer
    ///
    internal init(originalNote: String, newNote: String) {
        self.originalNote = originalNote
        self.newNote = originalNote
    }

    /// Update the note remotely and fire and try to dismiss the view.
    ///
    func updateNote() {
        // TODO: Fire network request & dismiss the view
        // Dummy code
        showLoadingIndicator = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showLoadingIndicator = false
        }
    }
}
