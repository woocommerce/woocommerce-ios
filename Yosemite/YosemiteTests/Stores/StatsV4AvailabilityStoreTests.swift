import XCTest
@testable import Yosemite
@testable import Networking

class StatsV4AvailabilityStoreTests: XCTestCase {
    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 123

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    // MARK: - StatsV4AvailabilityAction.checkStatsV4Availability

    /// Verifies that `StatsV4AvailabilityAction.checkStatsV4Availability` determines that
    /// Stats v4 is available with a remote response when WC admin is activated.
    ///
    func testCheckingStatsV4AvailabilityWithWCAdminActivated() {
        let expectation = self.expectation(description: "Check stats v4 availability")
        let statsStore = AvailabilityStore(dispatcher: dispatcher,
                                                  storageManager: storageManager,
                                                  network: network)

        network.simulateResponse(requestUrlSuffix: "reports/revenue/stats", filename: "order-stats-v4-wcadmin-activated")

        let action = AvailabilityAction.checkStatsV4Availability(siteID: sampleSiteID, onCompletion: { isStatsV4Available in
            XCTAssertTrue(isStatsV4Available)
            expectation.fulfill()
        })

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsV4AvailabilityAction.checkStatsV4Availability` determines that
    /// Stats v4 is not available with a remote response when WC admin is deactivated.
    ///
    func testCheckingStatsV4AvailabilityWithWCAdminDeactivated() {
        let expectation = self.expectation(description: "Check stats v4 availability")
        let statsStore = AvailabilityStore(dispatcher: dispatcher,
                                                  storageManager: storageManager,
                                                  network: network)

        network.simulateResponse(requestUrlSuffix: "reports/revenue/stats", filename: "order-stats-v4-wcadmin-deactivated")

        let action = AvailabilityAction.checkStatsV4Availability(siteID: sampleSiteID, onCompletion: { isStatsV4Available in
            XCTAssertFalse(isStatsV4Available)
            expectation.fulfill()
        })

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
