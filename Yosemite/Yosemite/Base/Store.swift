import Foundation
import Storage
import Networking


// MARK: - Store: Holds the data associated to a specific domain of the application.
//         Every store is subscribed to the global action dispatcher (although it can be initialized with a custom dispatcher), and should
//         respond to relevant Actions by implementing onAction(_:), and change its internal state according to those actions.
//
open class Store: ActionsProcessor {

    /// The dispatcher used to subscribe to Actions.
    ///
    public let dispatcher: Dispatcher

    /// Storage Layer
    ///
    public let storageManager: StorageManagerType

    /// Network Layer
    ///
    public let network: Network


    /// Initializes a new Store.
    ///
    /// - Parameters:
    ///     - dispatcher: the Dispatcher to use to receive Actions.
    ///     - storageManager: Storage Provider to be used in all of the current Store OP's.
    ///     - network: Network that should be used, when it comes to building a Remote.
    ///
    public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.dispatcher = dispatcher
        self.storageManager = storageManager
        self.network = network

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
    open func registerSupportedActions(in dispatcher: Dispatcher) {
        fatalError("Override me!")
    }

    /// This method is called for every Action. Subclasses should override this and deal with the Actions relevant to them.
    ///
    open func onAction(_ action: Action) {
        fatalError("Override me!")
    }
}

// MARK: - Default!
//
public extension Store {

    enum Default {
        public static let firstPageNumber: Int = Remote.Default.firstPageNumber
    }
}
