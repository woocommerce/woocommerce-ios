import UIKit

/// UI state of `ProductsViewController`.
///
/// - placeholder: <#placeholder description#>
/// - syncing: <#syncing description#>
/// - results: <#results description#>
/// - emptyUnfiltered: <#emptyUnfiltered description#>
/// - emptyFiltered: <#emptyFiltered description#>
enum ProductsViewControllerState {
    case placeholder
    case syncing
    case results
    case emptyUnfiltered
    case emptyFiltered
}

/// Keeps track of the Products view controller UI state, and allows the owning view controller to update UI when leaving and entering a state.
///
final class ProductsViewControllerStateCoordinator {
    typealias State = ProductsViewControllerState

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
    func transitionToSyncingState(hasData: Bool) {
        state = hasData ? .syncing: .placeholder
    }

    /// Should be called whenever the results are updated: after Sync'ing (or after applying a filter).
    /// Transitions to `.results` / `.emptyFiltered` / `.emptyUnfiltered` accordingly.
    ///
    func transitionToResultsUpdatedState(hasData: Bool) {
        if hasData {
            state = .results
            return
        }

        state = .emptyUnfiltered
    }
}
