import Foundation
import Yosemite
@testable import WooCommerce


/// MockStoresManager: StoresManager Mock!
///
final class MockStoresManager: DefaultStoresManager {

    /// Contains all of the dispatched Actions
    ///
    private(set) var receivedActions = [Action]()

    /// Callbacks to be called when a specific `Action` type is dispatched. The `key` is the
    /// `String` description of `Action.Type`.
    private var receivedActionCallbacks = [String: (Action) -> Void]()

    /// Indicates if the Actions should be dispatched for real (or do nothing!)
    ///
    var shouldDispatchActionsForReal = false

    /// Optional test coordinator for POS catalog sync
    ///
    var testPOSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol?

    /// Accept a concrete implementation (in addition to the pre-existing Protocol-based initializer)
    ///
    init(sessionManager: SessionManager) {
        super.init(sessionManager: sessionManager)
    }

    // MARK: - Overridden Properties

    override var posCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol? {
        testPOSCatalogSyncCoordinator
    }

    // MARK: - Overridden Methods

    override func dispatch(_ action: Action) {
        receivedActions.append(action)

        if shouldDispatchActionsForReal {
            super.dispatch(action)
        } else {
            if let callback = receivedActionCallbacks[String(describing: type(of: action))] {
                callback(action)
            } else {
                resolveDefaultIfNeeded(action)
            }
        }
    }

    /// Provides a sensible default response for actions whose completion must always be called to
    /// avoid leaking suspended continuations when a test does not register an explicit callback.
    ///
    private func resolveDefaultIfNeeded(_ action: Action) {
        switch action {
        case let action as FeatureFlagAction:
            // Mirror `FeatureFlagStore`: with no remote override configured, resolve to the local default.
            if case let .isRemoteFeatureFlagEnabled(_, defaultValue, _, completion) = action {
                completion(defaultValue)
            }
        default:
            break
        }
    }

    override func listenToWPCOMInvalidWPCOMTokenNotification() {
        // Don't listen to WPCOM token expiry notification to avoid de-authenticating while running tests.
    }

    // MARK: - Public Methods

    /// Restores the initial state
    ///
    func reset() {
        receivedActions = []
    }
}

// MARK: - Mocking

extension MockStoresManager {
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

    /// Resolves `FeatureFlagAction.isRemoteFeatureFlagEnabled` by returning the given fixed value,
    /// regardless of the local `defaultValue` — mimicking a remote override.
    ///
    func resolveRemoteFeatureFlag(returning value: Bool) {
        whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            if case let .isRemoteFeatureFlagEnabled(_, _, _, completion) = action {
                completion(value)
            }
        }
    }
}
