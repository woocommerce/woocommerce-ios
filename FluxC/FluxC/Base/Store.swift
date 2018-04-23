import Foundation


// MARK: - Store: Holds the data associated to a specific domain of the application.
//         Every store is subscribed to the global action dispatcher (although it can be initialized with a custom dispatcher), and should
//         respond to relevant Actions by implementing onAction(_:), and change its internal state according to those actions.
//
// NOTE: - Consumers can hook up to the EventBus, and listen for specific events.
//
open class Store: ActionsProcessor {

    /// The dispatcher used to subscribe to Actions.
    ///
    public let dispatcher: Dispatcher

    /// The dispatcher used to notify observer of changes.
    ///
    public let eventBus = EventBus()


    /// Initializes a new Store.
    ///
    /// - Parameter dispatcher: the Dispatcher to use to receive Actions.
    ///
    public init(dispatcher: Dispatcher = .global) {
        self.dispatcher = dispatcher
        registerSupportedActions()
    }

    /// Deinitializer
    ///
    deinit {
        dispatcher.unregister(processor: self)
    }


    // MARK: - Dispatcher's Delegate Methods

    /// Subclasses should override this and register for supported Dispatcher Actions.
    ///
    open func registerSupportedActions() {
        fatalError("Override me!")
    }

    /// This method is called for every Action. Subclasses should override this and deal with the Actions relevant to them.
    ///
    open func onAction(_ action: Action) {
        fatalError("Override me!")
    }
}
