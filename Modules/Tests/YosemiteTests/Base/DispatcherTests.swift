import XCTest
import Yosemite


// MARK: - Dispatcher Unit Tests!
//
class DispatcherTests: XCTestCase {

    var dispatcher: Dispatcher!
    var processor: MockActionsProcessor!

    override func setUp() {
        super.setUp()

        dispatcher = Dispatcher()
        processor = MockActionsProcessor()
    }


    /// Verifies that multiple instances of the same processor get properly registered.
    ///
    func testProcessorEffectivelyGetsRegistered() {
        let processor = MockActionsProcessor()
        dispatcher.register(processor: processor, for: MockSiteAction.self)
        XCTAssertTrue(dispatcher.isProcessorRegistered(processor, for: MockSiteAction.self))
    }

    /// Verifies that a processor only receives the actions it's been registered to.
    ///
    func testProcessorsReceiveOnlyRegisteredActions() {
        dispatcher.register(processor: processor, for: MockSiteAction.self)

        XCTAssertTrue(processor.receivedActions.isEmpty)
        dispatcher.dispatch(MockSiteAction.refreshSites)
        XCTAssertEqual(processor.receivedActions.count, 1)

        dispatcher.dispatch(MockAccountAction.authenticate)
        XCTAssertEqual(processor.receivedActions.count, 1)
    }

    /// Verifies that a registered processor receive all of the posted actions.
    ///
    func testProcessorsReceiveRegisteredActions() {
        dispatcher.register(processor: processor, for: MockSiteAction.self)
        XCTAssertTrue(processor.receivedActions.isEmpty)

        dispatcher.dispatch(MockSiteAction.refreshSites)
        XCTAssertEqual(processor.receivedActions.count, 1)

        dispatcher.dispatch(MockSiteAction.refreshSite(identifier: 123))
        XCTAssertEqual(processor.receivedActions.count, 2)
    }

    /// Verifies that, once unregistered, a processor stops receiving actions.
    ///
    func testUnregisteredProcessorsDoNotReceiveAnyActions() {
        XCTAssertTrue(processor.receivedActions.isEmpty)

        dispatcher.register(processor: processor, for: MockSiteAction.self)
        dispatcher.dispatch(MockSiteAction.refreshSites)
        XCTAssertEqual(processor.receivedActions.count, 1)

        dispatcher.unregister(processor: processor)
        dispatcher.dispatch(MockSiteAction.refreshSites)
        dispatcher.dispatch(MockAccountAction.authenticate)
        XCTAssertEqual(processor.receivedActions.count, 1)
    }

    /// Verifies that the Dispatcher does not strongly retain the ActionsProcessors.
    ///
    func testProcessorsAreNotStronglyRetainedByDispatcher() {
        dispatcher.register(processor: processor, for: MockSiteAction.self)
        XCTAssertNotNil(dispatcher.processor(for: MockSiteAction.self))
        processor = nil

        XCTAssertNil(dispatcher.processor(for: MockSiteAction.self))
    }
}
