import Foundation
import Yosemite
@testable import WooCommerce


/// MockupStoresManager: MockupStoresManager Mockup!
///
final class MockupStoresManager: DefaultStoresManager {

    /// Contains all of the dispatched Actions
    ///
    private(set) var receivedActions = [Action]()

    /// Callbacks to be called when a specific `Action` type is dispatched. The `key` is the
    /// `String` description of `Action.Type`.
    private var receivedActionCallbacks = [String: (Action) -> Void]()

    /// Indicates if the Actions should be dispatched for real (or do nothing!)
    ///
    var shouldDispatchActionsForReal = false


    // MARK: - Overridden Methods

    override func dispatch(_ action: Action) {
        receivedActions.append(action)

        if shouldDispatchActionsForReal {
            super.dispatch(action)
        } else {
            if let callback = receivedActionCallbacks[String(describing: type(of: action))] {
                callback(action)
            }
        }
    }

    // MARK: - Public Methods

    /// Restores the initial state
    ///
    func reset() {
        receivedActions = []
    }
}

// MARK: - Mocking

extension MockupStoresManager {
    /// When an action of type `actionType` is received, then call the given `callback`.
    ///
    /// Example usage:
    ///
    /// ```
    /// storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
    ///     if case let AppSettingsAction.loadInAppFeedbackCardVisibility(onCompletion) = action {
    ///         onCompletion(.success(true))
    ///     }
    /// }
    /// ```
    func whenReceivingAction<T: Action>(ofType actionType: T.Type, thenCall callback: @escaping (T) -> Void) {
        // This is one of those times in my life when I really feel like I don't know what I'm doing.
        // If there's a better way to do this, please let me know. ^_^x
        let wrappingCallback: (Action) -> Void = { action in
            if let typedAction = action as? T {
                callback(typedAction)
            }
        }
        let key = String(describing: actionType)
        receivedActionCallbacks[key] = wrappingCallback
    }
}
