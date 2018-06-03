import XCTest
@testable import FluxSumi


// MARK: - Dispatcher Unit Tests!
//
class DispatcherTests: XCTestCase {

    var dispatcher: MockupDispatcher!
    var processor: MockupProcessor!

    override func setUp() {
        super.setUp()

        dispatcher = MockupDispatcher()
        processor = MockupProcessor()
    }


    /// Verifies that multiple instances of the same processor get properly registered.
    ///
    func testMultipleProcessorInstancesGetProperlyRegistered() {
        var processors = [ActionsProcessor]()

        for _ in 0..<100 {
            let processor = MockupProcessor()
            dispatcher.register(processor: processor, actionType: SiteAction.self)
            processors.append(processor)

            XCTAssertEqual(processors.count, dispatcher.numberOfProcessors(for: SiteAction.self))
        }
    }

    /// Verifies that a processor only receives the actions it's been registered to.
    ///
    func testProcessorsReceiveOnlyRegisteredActions() {
        dispatcher.register(processor: processor, actionType: SiteAction.self)

        XCTAssertTrue(processor.receivedActions.isEmpty)
        dispatcher.dispatch(SiteAction.refreshSites)
        XCTAssertEqual(processor.receivedActions.count, 1)

        dispatcher.dispatch(AccountAction.authenticate)
        XCTAssertEqual(processor.receivedActions.count, 1)
    }

    /// Verifies that a registered processor receive all of the posted actions.
    ///
    func testProcessorsReceiveRegisteredActions() {
        dispatcher.register(processor: processor, actionType: SiteAction.self)
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

        dispatcher.register(processor: processor, actionType: SiteAction.self)
        dispatcher.dispatch(SiteAction.refreshSites)
        XCTAssertEqual(processor.receivedActions.count, 1)

        dispatcher.unregister(processor: processor)
        dispatcher.dispatch(SiteAction.refreshSites)
        dispatcher.dispatch(AccountAction.authenticate)
        XCTAssertEqual(processor.receivedActions.count, 1)
    }
}
