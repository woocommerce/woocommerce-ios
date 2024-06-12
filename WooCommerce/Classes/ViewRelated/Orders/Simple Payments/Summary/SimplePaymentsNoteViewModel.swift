import Foundation
import Combine
import protocol WooFoundation.Analytics

final class SimplePaymentsNoteViewModel: EditCustomerNoteViewModelProtocol {

    /// Store for the edited content
    ///
    @Published var newNote: String

    /// Defines the navigation right button state
    ///
    @Published private(set) var navigationTrailingItem: EditCustomerNoteNavigationItem = .done(enabled: false)

    /// Commit the original note.
    ///
    func updateNote(onCompletion: @escaping (Bool) -> Void) {
        originalNote = newNote
        onCompletion(true)

        analytics.track(event: .SimplePayments.simplePaymentsFlowNoteAdded())
    }

    /// Revert to original content.
    ///
    func userDidCancelFlow() {
        newNote = originalNote
    }

    /// Stores the original note content.
    ///
    @Published private var originalNote: String

    /// Analytics engine.
    ///
    private let analytics: Analytics

    init(originalNote: String = "", analytics: Analytics = ServiceLocator.analytics) {
        self.originalNote = originalNote
        self.newNote = originalNote
        self.analytics = analytics
        bindNoteChanges()
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
