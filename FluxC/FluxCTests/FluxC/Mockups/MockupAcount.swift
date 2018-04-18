import Foundation
import FluxC


// MARK: - Represents an Account Action.
//
enum AccountAction: Action {
    case authenticate
    case deauthenticate
}


// MARK: - Represents an Account Event.
//
enum AccountEvent: Event {
    case authenticated
    case deauthenticated
}


// MARK: - Account Events Listener Mockup Instance.
//
class MockupAccountEventsListener: EventsListener {

    var receivedEvents = [AccountEvent]()

    func onEvent(_ event: Event) {
        guard let event = event as? AccountEvent else {
            return
        }

        receivedEvents.append(event)
    }
}


// MARK: - Account Mockup Store.
//
class MockupAccountStore: Store {

    var receivedActions = [AccountAction]()

    override func onAction(_ action: Action) {
        guard let accountAction = action as? AccountAction else {
            fatalError()
        }

        receivedActions.append(accountAction)
    }
}
