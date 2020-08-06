import Foundation
import Yosemite
@testable import WooCommerce


/// MockupStoresManager: MockupStoresManager Mockup!
///
final class MockupStoresManager: DefaultStoresManager {

    /// Contains all of the dispatched Actions
    ///
    private(set) var receivedActions = [Action]()

    /// Indicates if the Actions should be dispatched for real (or do nothing!)
    ///
    var shouldDispatchActionsForReal = false


    // MARK: - Overridden Methods

    override func dispatch(_ action: Action) {
        receivedActions.append(action)

        guard shouldDispatchActionsForReal else {
            return
        }

        super.dispatch(action)
    }

    // MARK: - Public Methods

    /// Restores the initial state
    ///
    func reset() {
        receivedActions = []
    }
}
