import Foundation
import Combine

final class OrderNotesViewModel: EditCustomerNoteViewModelProtocol {

    /// Binding property modified at the view level.
    ///
    @Published var newNote: String

    /// Defaults to a disabled done button.
    ///
    @Published private(set) var navigationTrailingItem: EditCustomerNoteNavigationItem = .done(enabled: false)

    /// Defaults to `nil`.
    ///
    @Published var presentNotice: EditCustomerNoteNotice?

    /// Publisher accessor for `presentNotice`. Needed for the protocol conformance.
    ///
    var presentNoticePublisher: Published<EditCustomerNoteNotice?>.Publisher {
        $presentNotice
    }

    /// Analytics center.
    ///
    private let analytics: Analytics = ServiceLocator.analytics

    /// Stores the original note content.
    ///
    @Published private var originalNote: String

    init(originalNote: String = "") {
        self.originalNote = originalNote
        self.newNote = originalNote
        bindNoteChanges()
    }

    func updateNote(onFinish: @escaping (Bool) -> Void) {
        originalNote = newNote
        onFinish(true)
    }

    func userDidCancelFlow() {
        newNote = originalNote
    }

    /// Assigns the correct navigation trailing item as the new note content changes.
    ///
    private func bindNoteChanges() {
        Publishers.CombineLatest($newNote, $originalNote)
            .map { editedContent, originalNote -> EditCustomerNoteNavigationItem in
                .done(enabled: editedContent != originalNote)
            }
            .assign(to: &$navigationTrailingItem)
    }
}
