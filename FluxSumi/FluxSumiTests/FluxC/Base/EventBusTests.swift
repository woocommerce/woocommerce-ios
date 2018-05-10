import XCTest
@testable import FluxSumi


// MARK: - EventBus Unit Tests!
//
class EventBusTests: XCTestCase {

    var eventBus: EventBus!
    var accountEventsListener: MockupAccountEventsListener!
    var siteEventsListener: MockupSiteEventsListener!

    override func setUp() {
        eventBus = EventBus()
        accountEventsListener = MockupAccountEventsListener()
        siteEventsListener = MockupSiteEventsListener()

        eventBus.subscribe(accountEventsListener)
        eventBus.subscribe(siteEventsListener)
    }


    /// Verifies that Event Listeners only received those events that return true when `isSupported` is queried.
    ///
    func testListenersOnlyReceiveTargetedEvents() {
        XCTAssertTrue(accountEventsListener.receivedEvents.isEmpty)

        eventBus.emit(AccountEvent.authenticated)
        XCTAssertEqual(accountEventsListener.receivedEvents.count, 1)
        XCTAssertTrue(siteEventsListener.receivedEvents.isEmpty)
    }

    /// Verifies that Event Listeners that are unsubscribed stop receiving events.
    ///
    func testUnsubscribedListenersStopReceivingEvents() {
        eventBus.emit(AccountEvent.authenticated)
        XCTAssertEqual(accountEventsListener.receivedEvents.count, 1)

        eventBus.unsubscribe(accountEventsListener)
        eventBus.emit(AccountEvent.authenticated)
        XCTAssertEqual(accountEventsListener.receivedEvents.count, 1)
    }
}
