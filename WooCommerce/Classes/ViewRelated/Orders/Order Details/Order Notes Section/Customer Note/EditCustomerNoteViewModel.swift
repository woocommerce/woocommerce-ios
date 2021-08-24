import Foundation
import Yosemite
import Combine

/// View Model for the Edit Customer Note screen
///
final class EditCustomerNoteViewModel: ObservableObject {

    /// New content to submit.
    /// Binding property modified at the view level.
    ///
    @Published var newNote: String

    /// Active navigation bar trailing item.
    /// Defaults to a disabled done button.
    ///
    @Published private(set) var navigationTrailingItem: NavigationItem = .done(enabled: false)

    /// Original content of the order customer provided note.
    ///
    private let originalNote: String

    /// Tracks if a network request is being performed.
    ///
    private let performingNetworkRequest: CurrentValueSubject<Bool, Never> = .init(false)

    convenience init(order: Order) {
        let note = order.customerNote ?? ""
        self.init(originalNote: note, newNote: note)
    }

    /// Member wise initializer
    ///
    init(originalNote: String, newNote: String) {
        self.originalNote = originalNote
        self.newNote = originalNote
        bindNavigationTrailingItemPublisher()
    }

    /// Update the note remotely and invoke a completion block when finished
    ///
    func updateNote(onFinish: @escaping () -> Void) {
        // TODO: Fire network request
        performingNetworkRequest.send(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.performingNetworkRequest.send(false)
            onFinish()
        }
    }
}

// MARK: Definitions
extension EditCustomerNoteViewModel {
    /// Representation of possible navigation bar trailing buttons
    ///
    enum NavigationItem {
        case done(enabled: Bool)
        case loading
    }
}

// MARK: Helper Methods
private extension EditCustomerNoteViewModel {
    /// Calculates what navigation trailing item should be shown depending on our internal state.
    ///
    private func bindNavigationTrailingItemPublisher() {
        Publishers.CombineLatest($newNote, performingNetworkRequest)
            .map { [originalNote] newNote, performingNetworkRequest -> NavigationItem in
                guard !performingNetworkRequest else {
                    return .loading
                }
                return .done(enabled: originalNote != newNote)
            }
            .assign(to: &$navigationTrailingItem)
    }
}
