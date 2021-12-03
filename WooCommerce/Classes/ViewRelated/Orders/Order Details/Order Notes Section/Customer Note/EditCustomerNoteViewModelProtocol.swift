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

    /// A closure to be called when this view wants its creator to update the string and dismiss it.
    ///
    var didSelectDone: ((String) -> Void)? { get }

    /// Update when you need to update the note (remotely or locally) and invoke a completion block when finished
    ///
    func updateNote(onFinish: @escaping (Bool) -> Void)

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

/// Representation of possible notices that can be displayed
///
enum EditCustomerNoteNotice: Equatable {
    case success
    case error
}
