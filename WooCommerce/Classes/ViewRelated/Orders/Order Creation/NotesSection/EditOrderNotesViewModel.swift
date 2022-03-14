import Foundation
import Combine

class OrderCreationNotesViewModel: EditCustomerNoteViewModelProtocol {
    /// Store for the edited content
    ///
    @Published var newNote: String

    /// Defines the navigation right button state
    ///
    @Published private(set) var navigationTrailingItem: EditCustomerNoteNavigationItem = .done(enabled: false)

    /// Not used.
    ///
    @Published var presentNotice: EditCustomerNoteNotice? = nil

    /// Not used.
    ///
    var presentNoticePublisher: Published<EditCustomerNoteNotice?>.Publisher {
        $presentNotice
    }

    /// Commit the original note.
    ///
    func updateNote(onFinish: @escaping (Bool) -> Void) {
        originalNote = newNote
        onFinish(true)

        updateNoteAnalyticsTrackAction()
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
    private let updateNoteAnalyticsTrackAction: () -> Void

    init(originalNote: String = "", updateNoteAnalyticsTrackAction: @escaping () -> Void) {
        self.originalNote = originalNote
        self.newNote = originalNote
        self.updateNoteAnalyticsTrackAction = updateNoteAnalyticsTrackAction
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
