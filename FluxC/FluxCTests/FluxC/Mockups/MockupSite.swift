import Foundation
import FluxC


// MARK: - Represents a Site Action.
//
enum SiteAction: Action {
    case refreshSite(identifier: Int)
    case refreshSites
}


// MARK: - Represents a Site Event.
//
enum SiteEvent: Event {
    case refreshedSite(identifier: Int)
    case refreshedSites
}


// MARK: - Site Events Listener Mockup Instance.
//
class MockupSiteEventsListener: EventsListener {

    var receivedEvents = [SiteEvent]()

    func onEvent(_ event: Event) {
        guard let event = event as? SiteEvent else {
            return
        }

        receivedEvents.append(event)
    }
}


// MARK: - Account Site Store.
//
class MockupSiteStore: Store {

    var receivedActions = [SiteAction]()

    override func registerSupportedActions() {
        dispatcher.register(processor: self, actionType: SiteAction.self)
    }

    override func onAction(_ action: Action) {
        guard let accountAction = action as? SiteAction else {
            return
        }

        receivedActions.append(accountAction)
    }
}
