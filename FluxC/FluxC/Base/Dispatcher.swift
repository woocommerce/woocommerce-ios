import Foundation


// MARK: - Action: Represents a FluxC Action.
//
public protocol Action {}


// MARK: - Action: Represents a FluxC Action Processor. Processors should get registered into the Dispatcher instance, for action processing.
//
public protocol ActionsProcessor: class {

    /// Called whenever a given Action is dispatched.
    ///
    func onAction(_ action: Action)
}


// MARK: - Dispatcher: A Dispatcher broadcasts an Action to all registered subscribers.
//         You can think of it as a strongly typed NotificationCenter, if it had been written for Swift instead of Objective-C.
//
// NOTE: - Dispatcher is not thread safe yet, and it expects its methods to be called from the main thread only.
//
public class Dispatcher {

    /// Shared global dispatcher
    ///
    public static let global = Dispatcher()

    /// Collection of active Action Processors.
    ///
    var processors = [ObjectIdentifier: ActionsProcessor]()


    /// Indicates if a Processor is registered in the current Dispatcher.
    ///
    public func isRegistered(_ processor: ActionsProcessor) -> Bool {
        let identifier = ObjectIdentifier(processor)
        return processors[identifier] != nil
    }

    /// Register a new Processor to call whenever an action is dispatched.
    ///
    public func register(_ processor: ActionsProcessor) {
        assertMainThread()

        let identifier = ObjectIdentifier(processor)
        processors[identifier] = processor
    }

    /// Unregisters the specified Processor from the dispatch handlers.
    ///
    public func unregister(_ processor: ActionsProcessor) {
        assertMainThread()

        let identifier = ObjectIdentifier(processor)
        processors.removeValue(forKey: identifier)
    }

    /// Dispatches the given action to all registered processors.
    ///
    public func dispatch(_ action: Action) {
        assertMainThread()

        for processor in processors.values {
            processor.onAction(action)
        }
    }
}
