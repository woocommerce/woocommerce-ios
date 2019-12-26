import UIKit

/// UI state of a view controller that displays a paginated list.
///
/// - noResultsPlaceholder: a no results placeholder is displayed
/// - syncing: syncing data UI with a parameter that indicates whether there is existing data
/// - results: the results are shown
enum PaginatedListViewControllerState {
    case noResultsPlaceholder
    case syncing(withExistingData: Bool)
    case results
}

extension PaginatedListViewControllerState: Equatable {
    static func ==(lhs: PaginatedListViewControllerState, rhs: PaginatedListViewControllerState) -> Bool {
            switch (lhs, rhs) {
            case let (.syncing(lhs), .syncing(rhs)):
                return lhs == rhs
            case (.noResultsPlaceholder, .noResultsPlaceholder):
                return true
            case (.results, .results):
                return true
            default:
                return false
            }
    }
}

/// Keeps track of the paginated list view controller UI state, and allows the owning view controller to update UI when leaving and entering a state.
///
final class PaginatedListViewControllerStateCoordinator {
    typealias State = PaginatedListViewControllerState

    private let onLeavingState: (_ state: State) -> Void
    private let onEnteringState: (_ state: State) -> Void

    init(onLeavingState: @escaping (_ state: State) -> Void,
         onEnteringState: @escaping (_ state: State) -> Void) {
        self.onLeavingState = onLeavingState
        self.onEnteringState = onEnteringState
    }

    /// UI Active State
    ///
    private var state: State = .results {
        didSet {
            guard oldValue != state else {
                return
            }

            onLeavingState(oldValue)
            onEnteringState(state)
        }
    }

    /// Should be called before Sync'ing. Transitions to either `results` or `placeholder` state, depending on whether if
    /// we've got cached results, or not.
    ///
    func transitionToSyncingState(withExistingData: Bool) {
        state = .syncing(withExistingData: withExistingData)
    }

    /// Should be called whenever the results are updated: after Sync'ing (or after applying a filter).
    ///
    func transitionToResultsUpdatedState(hasData: Bool) {
        state = hasData ? .results: .noResultsPlaceholder
    }
}
