import Foundation


// MARK: - Action: Represents a FluxC Action.
//
public protocol Action { }


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

    /// Collection of active Action Processors, per action kind.
    ///
    var processors = [Action.TypeIdentifier: [ActionsProcessor]]()


    /// Registers the specified processor to receive Actions of a given kind.
    ///
    public func register(processor: ActionsProcessor, actionType: Action.Type) {
        assertMainThread()

        var updated = processors[actionType.identifier] ?? []
        updated.append(processor)
        processors[actionType.identifier] = updated
    }

    /// Unregisters the specified Processor from *ALL* of the dispatcher queues.
    ///
    public func unregister(processor: ActionsProcessor) {
        assertMainThread()

        let removedProcessorIdentifier = ObjectIdentifier(processor)
        for (identifier, subprocessors) in processors {
            processors[identifier] = subprocessors.filter { ObjectIdentifier($0) != removedProcessorIdentifier }
        }
    }

    /// Dispatches the given action to all registered processors.
    ///
    public func dispatch(_ action: Action) {
        assertMainThread()

        let identifier = type(of: action).identifier
        processors[identifier]?.forEach { processor in
            processor.onAction(action)
        }
    }
}
