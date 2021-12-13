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
        dispatcher.register(processor: processor, for: SiteAction.self)
        XCTAssertTrue(dispatcher.isProcessorRegistered(processor, for: SiteAction.self))
    }

    /// Verifies that a processor only receives the actions it's been registered to.
    ///
    func testProcessorsReceiveOnlyRegisteredActions() {
        dispatcher.register(processor: processor, for: SiteAction.self)

        XCTAssertTrue(processor.receivedActions.isEmpty)
        dispatcher.dispatch(SiteAction.refreshSites)
        XCTAssertEqual(processor.receivedActions.count, 1)

        dispatcher.dispatch(MockAccountAction.authenticate)
        XCTAssertEqual(processor.receivedActions.count, 1)
    }

    /// Verifies that a registered processor receive all of the posted actions.
    ///
    func testProcessorsReceiveRegisteredActions() {
        dispatcher.register(processor: processor, for: SiteAction.self)
        XCTAssertTrue(processor.receivedActions.isEmpty)

        dispatcher.dispatch(SiteAction.refreshSites)
        XCTAssertEqual(processor.receivedActions.count, 1)

        dispatcher.dispatch(SiteAction.refreshSite(identifier: 123))
        XCTAssertEqual(processor.receivedActions.count, 2)
    }

    /// Verifies that, once unregistered, a processor stops receiving actions.
    ///
    func testUnregisteredProcessorsDoNotReceiveAnyActions() {
        XCTAssertTrue(processor.receivedActions.isEmpty)

        dispatcher.register(processor: processor, for: SiteAction.self)
        dispatcher.dispatch(SiteAction.refreshSites)
        XCTAssertEqual(processor.receivedActions.count, 1)

        dispatcher.unregister(processor: processor)
        dispatcher.dispatch(SiteAction.refreshSites)
        dispatcher.dispatch(MockAccountAction.authenticate)
        XCTAssertEqual(processor.receivedActions.count, 1)
    }

    /// Verifies that the Dispatcher does not strongly retain the ActionsProcessors.
    ///
    func testProcessorsAreNotStronglyRetainedByDispatcher() {
        dispatcher.register(processor: processor, for: SiteAction.self)
        XCTAssertNotNil(dispatcher.processor(for: SiteAction.self))
        processor = nil

        XCTAssertNil(dispatcher.processor(for: SiteAction.self))
    }
}
