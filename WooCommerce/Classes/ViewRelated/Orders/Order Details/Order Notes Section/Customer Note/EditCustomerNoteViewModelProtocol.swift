import Foundation
import Combine

/// Protocol for abstracting how to serve and interact with content within a `EditCustomerNote` view.
///
protocol EditCustomerNoteViewModelProtocol: ObservableObject {

    /// New content to submit.
    ///
    var newNote: String { get set }

    /// Active navigation bar trailing item.
    ///
    var navigationTrailingItem: EditCustomerNoteNavigationItem { get }

    /// Call it when the user taps on the button Done.
    ///
    /// Use this method when you need to update the note (remotely or locally) and invoke a
    /// completion block when finished
    ///
    @MainActor
    func updateNote(onCompletion: @escaping (Bool) -> Void)

    /// Call it when the user cancels the flow.
    ///
    func userDidCancelFlow()
}

/// Representation of possible navigation bar trailing buttons
///
enum EditCustomerNoteNavigationItem: Equatable {
    case done(enabled: Bool)
    case loading
}
