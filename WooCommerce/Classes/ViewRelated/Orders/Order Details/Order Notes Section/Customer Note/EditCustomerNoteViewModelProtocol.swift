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

    /// Update when you need to update the note (remotely or locally) and invoke a completion block when finished
    ///
    func updateNote(onFinish: @escaping (Bool) -> Void)

    /// Call it when the user cancels the flow.
    ///
    func userDidCancelFlow()

    /// Indicates whether we must wait for the request before dismiss. Default: **false**
    ///
    var shouldWaitForRequestIsFinishedToDismiss: Bool { get }
}

extension EditCustomerNoteViewModelProtocol {
    /// By default we haven't to wait for the request is finished
    /// to dismiss the view.
    ///
    var shouldWaitForRequestIsFinishedToDismiss: Bool {
        return false
    }
}

/// Representation of possible navigation bar trailing buttons
///
enum EditCustomerNoteNavigationItem: Equatable {
    case done(enabled: Bool)
    case loading
}
