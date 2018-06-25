import Foundation


// MARK: - Action: Represents a Flux Action.
//
public protocol Action { }


// MARK: - Action: Represents a Flux Action Processor. Processors should get registered into the Dispatcher instance, for action processing.
//
public protocol ActionsProcessor: class {

    /// Called whenever a given Action is dispatched.
    ///
    func onAction(_ action: Action)
}


// MARK: - Dispatcher: A Dispatcher broadcasts an Action to all registered subscribers.
//                     One Action can only have One Processor!
//
// NOTE: - Dispatcher is not thread safe yet, and it expects its methods to be called from the main thread only.
//
public class Dispatcher {

    /// Collection of active Action Processors, per action kind.
    ///
    private(set) var processors = [Action.TypeIdentifier: ActionsProcessor]()


    ///  Designated Initializer
    ///
    public init() {}

    /// Registers the specified processor to receive Actions of a given kind.
    ///
    public func register(processor: ActionsProcessor, for actionType: Action.Type) {
        assertMainThread()

        guard processors[actionType.identifier] == nil else {
            fatalError("An action type can only be handled by a single processor!")
        }

        processors[actionType.identifier] = processor
    }

    /// Unregisters the specified Processor from *ALL* of the dispatcher queues.
    ///
    public func unregister(processor: ActionsProcessor) {
        assertMainThread()

        for (identifier, subprocessor) in processors where subprocessor.identifier == processor.identifier {
            processors[identifier] = nil
        }
    }

    /// Indicates if an ActionProcessor is registered to handle a given ActionType
    ///
    public func isProcessorRegistered(_ processor: ActionsProcessor, for actionType: Action.Type) -> Bool {
        return processors[actionType.identifier]?.identifier == processor.identifier
    }

    /// Dispatches the given action to all registered processors.
    ///
    public func dispatch(_ action: Action) {
        assertMainThread()

        processors[action.identifier]?.onAction(action)
    }
}
