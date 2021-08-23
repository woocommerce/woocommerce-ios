import Foundation
import Yosemite

/// View Model for the Edit Customer Note screen
///
final class EditCustomerNoteViewModel {

    /// Original content of the order customer provided note
    ///
    private let originalNote: String

    /// New content to submit
    ///
    private var newNote: String

    /// True when there are changes to the `initialNote`. False otherwise.
    ///
    var doneEnabled: Bool {
        originalNote != newNote
    }

    init(order: Order) {
        self.originalNote = order.customerNote ?? ""
        self.newNote = self.originalNote
    }

    /// Member wise initializer
    ///
    internal init(originalNote: String, newNote: String) {
        self.originalNote = originalNote
        self.newNote = newNote
    }
}
