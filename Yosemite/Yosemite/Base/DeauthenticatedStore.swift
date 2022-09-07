import Foundation
import Networking
import WooFoundation

// MARK: - DeauthenticatedStore: Holds the data associated to a specific domain of the application in the deauthenticated state.
//         Every store is subscribed to the global action dispatcher (although it can be initialized with a custom dispatcher), and should
//         respond to relevant Actions by implementing onAction(_:), and change its internal state according to those actions.
//
public class DeauthenticatedStore: ActionsProcessor {

    /// The dispatcher used to subscribe to Actions.
    ///
    public let dispatcher: Dispatcher


    /// Initializes a new DeauthenticatedStore.
    ///
    /// - Parameters:
    ///     - dispatcher: the Dispatcher to use to receive Actions.
    ///
    public init(dispatcher: Dispatcher) {
        self.dispatcher = dispatcher

        registerSupportedActions(in: dispatcher)
    }

    /// Deinitializer
    ///
    deinit {
        dispatcher.unregister(processor: self)
    }


    // MARK: - Dispatcher's Delegate Methods

    /// Subclasses should override this and register for supported Dispatcher Actions.
    ///
    public func registerSupportedActions(in dispatcher: Dispatcher) {
        logErrorAndExit("Override me!")
    }

    /// This method is called for every Action. Subclasses should override this and deal with the Actions relevant to them.
    ///
    public func onAction(_ action: Action) {
        logErrorAndExit("Override me!")
    }
}
