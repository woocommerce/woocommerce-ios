import XCTest
@testable import FluxC


// MARK: - Dispatcher Unit Tests!
//
class DispatcherTests: XCTestCase {

    var dispatcher: MockupDispatcher!
    var processor: MockupProcessor!

    override func setUp() {
        super.setUp()

        dispatcher = MockupDispatcher()
        processor = MockupProcessor()
        dispatcher.register(processor)
    }


    /// Verifies that multiple instances of the same processor get properly registered.
    ///
    func testMultipleProcessorInstancesGetProperlyRegistered() {
        var processors = Array(dispatcher.processors.values)

        for _ in 0..<100 {
            let processor = MockupProcessor()
            dispatcher.register(processor)
            processors.append(processor)

            XCTAssertEqual(processors.count, dispatcher.numberOfProcessors)
        }
    }

    /// Verifies that a single Processor instance can only be registered once.
    ///
    func testProcessorGetsRegisteredJustOnce() {
        for _ in 0..<100 {
            dispatcher.register(processor)
        }

        XCTAssertEqual(dispatcher.numberOfProcessors, 1)
    }

    /// Verifies that a registered processor receive all of the posted actions.
    ///
    func testRegisteredProcessorsReceiveActions() {
        XCTAssertTrue(processor.receivedActions.isEmpty)
        dispatcher.dispatch(SiteAction.refreshSites)
        XCTAssertEqual(processor.receivedActions.count, 1)

        dispatcher.dispatch(SiteAction.refreshSite(identifier: 123))
        XCTAssertEqual(processor.receivedActions.count, 2)
    }

    /// Verifies that, once unregistered, a processor stops receiving actions.
    ///
    func testUnregisteredProcessorsDoNotReceiveActions() {
        XCTAssertTrue(processor.receivedActions.isEmpty)

        dispatcher.unregister(processor)
        dispatcher.dispatch(SiteAction.refreshSites)
        XCTAssertTrue(processor.receivedActions.isEmpty)
    }
}
