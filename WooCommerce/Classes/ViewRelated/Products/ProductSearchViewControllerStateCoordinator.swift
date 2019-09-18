import UIKit

/// UI state of `ProductSearchViewController`.
///
/// - noResultsPlaceholder: a no results placeholder is displayed
/// - syncing: syncing data UI
/// - results: the results are shown
enum ProductSearchViewControllerState {
    case noResultsPlaceholder
    case syncing
    case results
}

/// Keeps track of the Product Search view controller UI state, and allows the owning view controller to update UI when
/// leaving and entering a state.
///
final class ProductSearchViewControllerStateCoordinator {
    typealias State = ProductSearchViewControllerState

    private let onLeavingState: (_ state: State) -> Void
    private let onEnteringState: (_ state: State) -> Void

    init(onLeavingState: @escaping (_ state: State) -> Void,
         onEnteringState: @escaping (_ state: State) -> Void) {
        self.onLeavingState = onLeavingState
        self.onEnteringState = onEnteringState
    }

    /// UI Active State
    ///
    private var state: State = .noResultsPlaceholder {
        didSet {
            guard oldValue != state else {
                return
            }

            onLeavingState(oldValue)
            onEnteringState(state)
        }
    }

    /// Should be called before Sync'ing. Transitions to either `results` state.
    ///
    func transitionToSyncingState() {
        state = .syncing
    }

    /// Should be called whenever new results have been retrieved. Transitions to `.results` / `.noResultsPlaceholder` accordingly.
    ///
    func transitionToResultsUpdatedState(hasData: Bool) {
        state = hasData ? .results : .noResultsPlaceholder
    }
}
