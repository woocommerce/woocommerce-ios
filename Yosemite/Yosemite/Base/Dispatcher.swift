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
    private var processors = [Action.TypeIdentifier: WeakProcessor]()


    ///  Designated Initializer
    ///
    public init() {}

    /// Registers the specified processor to receive Actions of a given kind.
    ///
    public func register(processor: ActionsProcessor, for actionType: Action.Type) {
        assertMainThread()

        guard processors[actionType.identifier] == nil else {
            logErrorAndExit("An action type can only be handled by a single processor!")
        }

        processors[actionType.identifier] = WeakProcessor(processor: processor)
    }

    /// Unregisters the specified Processor from *ALL* of the dispatcher queues.
    ///
    public func unregister(processor: ActionsProcessor) {
        for (identifier, subprocessor) in processors where subprocessor.identifier == processor.identifier {
            processors[identifier] = nil
        }
    }

    /// Indicates if an ActionProcessor is registered to handle a given ActionType
    ///
    public func isProcessorRegistered(_ processor: ActionsProcessor, for actionType: Action.Type) -> Bool {
        return processors[actionType.identifier]?.identifier == processor.identifier
    }

    /// Returns the registered ActionsProcessor, for a specified Action, if any exist.
    ///
    public func processor(for actionType: Action.Type) -> ActionsProcessor? {
        return processors[actionType.identifier]?.processor
    }

    /// Dispatches the given action to all registered processors.
    ///
    public func dispatch(_ action: Action) {
        assertMainThread()

        processors[action.identifier]?.onAction(action)
    }
}


// MARK: - WeakProcessor: Allows us to weakly-store ActionProcessors, and thus, prevent retain cycles.
//
private class WeakProcessor {

    /// The actual ActionsProcessor we're proxying.
    ///
    private(set) weak var processor: ActionsProcessor?

    /// Returns the internal Processor's Identifier, if any.
    ///
    var identifier: ActionsProcessor.TypeIdentifier? {
        return processor?.identifier
    }

    /// Designated Initializer
    ///
    init(processor: ActionsProcessor) {
        self.processor = processor
    }

    /// Called whenever a given Action is dispatched.
    ///
    func onAction(_ action: Action) {
        processor?.onAction(action)
    }
}
