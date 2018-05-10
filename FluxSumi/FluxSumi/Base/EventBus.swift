import Foundation


// MARK: - Event: Represents a Flux event.
//
public protocol Event {}


// MARK: - Listener: Represents a Flux Event Listener.
//
public protocol EventsListener: class {

    /// Called whenever a given Event is emitted.
    ///
    func onEvent(_ event: Event)
}


// MARK: - EventBus: Publisher / Subscriber tool, that helps us relay *Events* to the interested *Listeners*.
//
public class EventBus {

    /// Collection of Active Listeners.
    ///
    private var listeners = [ObjectIdentifier: EventsListener]()


    /// Adds a given listener to the current bus.
    ///
    public func subscribe(_ listener: EventsListener) {
        let identifier = ObjectIdentifier(listener)
        listeners[identifier] = listener
    }

    /// Removes a listener from the current bus.
    ///
    public func unsubscribe(_ listener: EventsListener) {
        let identifier = ObjectIdentifier(listener)
        listeners.removeValue(forKey: identifier)
    }

    /// Posts an Event to all of those who may hear.
    ///
    public func emit(_ event: Event) {
        for listener in listeners.values {
            listener.onEvent(event)
        }
    }
}
