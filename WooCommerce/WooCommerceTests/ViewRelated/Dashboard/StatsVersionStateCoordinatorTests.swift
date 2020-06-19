import XCTest
import Storage
import Yosemite
@testable import WooCommerce

final class StatsVersionStateCoordinatorTests: XCTestCase {
    private var mockStoresManager: MockupStatsVersionStoresManager!

    override func tearDown() {
        mockStoresManager = nil
        super.tearDown()
    }

    func testWhenV4IsAvailableWhileNoStatsVersionWasShownBefore() {
        // Given
        mockStoresManager = MockupStatsVersionStoresManager(sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = true
        ServiceLocator.setStores(mockStoresManager)

        let expectedStates: [StatsVersionState] = [.initial(statsVersion: .v3), .v3ShownV4Eligible]

        // When
        var states: [StatsVersionState] = []
        waitForExpectation { exp in
            let stateCoordinator = StatsVersionStateCoordinator(siteID: 134)
            stateCoordinator.onStateChange = { _, state in
                states.append(state)
                if states.count >= expectedStates.count {
                    exp.fulfill()
                }
            }

            stateCoordinator.loadLastShownVersionAndCheckV4Eligibility()
        }

        // Then
        XCTAssertEqual(states, expectedStates)
    }

    func testWhenV4IsUnavailableWhileNoStatsVersionWasShownBefore() {
        mockStoresManager = MockupStatsVersionStoresManager(sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)

        let expectedStates: [StatsVersionState] = [.initial(statsVersion: .v3), .eligible(statsVersion: .v3)]
        let expectation = self.expectation(description: "Wait for states to match")
        expectation.expectedFulfillmentCount = 1

        var states: [StatsVersionState] = []
        let stateCoordinator = StatsVersionStateCoordinator(siteID: 134)
        stateCoordinator.onStateChange = { _, state in
            states.append(state)
            if states.count >= expectedStates.count {
                XCTAssertEqual(states, expectedStates)
                expectation.fulfill()
            }
        }
        stateCoordinator.loadLastShownVersionAndCheckV4Eligibility()
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    /// Stats v3 --> v4
    func testWhenV4IsAvailableWhileStatsV3IsLastShown() {
        mockStoresManager = MockupStatsVersionStoresManager(initialStatsVersionLastShown: .v3,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = true
        ServiceLocator.setStores(mockStoresManager)

        let expectedStates: [StatsVersionState] = [.initial(statsVersion: .v3), .v3ShownV4Eligible]
        let expectation = self.expectation(description: "Wait for states to match")
        expectation.expectedFulfillmentCount = 1

        var states: [StatsVersionState] = []
        let stateCoordinator = StatsVersionStateCoordinator(siteID: 134)
        stateCoordinator.onStateChange = { _, state in
            states.append(state)
            if states.count >= expectedStates.count {
                XCTAssertEqual(states, expectedStates)
                expectation.fulfill()
            }
        }
        stateCoordinator.loadLastShownVersionAndCheckV4Eligibility()
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    /// Stats v3 --> v3
    func testWhenV4IsUnavailableWhileStatsV3IsLastShown() {
        mockStoresManager = MockupStatsVersionStoresManager(initialStatsVersionLastShown: .v3,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)

        let expectedStates: [StatsVersionState] = [.initial(statsVersion: .v3), .eligible(statsVersion: .v3)]
        let expectation = self.expectation(description: "Wait for states to match")
        expectation.expectedFulfillmentCount = 1

        var states: [StatsVersionState] = []
        let stateCoordinator = StatsVersionStateCoordinator(siteID: 134)
        stateCoordinator.onStateChange = { _, state in
            states.append(state)
            if states.count >= expectedStates.count {
                XCTAssertEqual(states, expectedStates)
                expectation.fulfill()
            }
        }
        stateCoordinator.loadLastShownVersionAndCheckV4Eligibility()
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    /// Stats v4 --> v3
    func testWhenV4IsUnavailableWhileStatsV4IsLastShown() {
        mockStoresManager = MockupStatsVersionStoresManager(initialStatsVersionLastShown: .v4,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)

        let expectedStates: [StatsVersionState] = [.initial(statsVersion: .v4), .v4RevertedToV3]
        let expectation = self.expectation(description: "Wait for states to match")
        expectation.expectedFulfillmentCount = 1

        var states: [StatsVersionState] = []
        let stateCoordinator = StatsVersionStateCoordinator(siteID: 134)
        stateCoordinator.onStateChange = { _, state in
            states.append(state)
            if states.count >= expectedStates.count {
                XCTAssertEqual(states, expectedStates)
                expectation.fulfill()
            }
        }
        stateCoordinator.loadLastShownVersionAndCheckV4Eligibility()
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    /// V4 --> v4
    func testWhenV4IsAvailableWhileStatsV4IsLastShown() {
        mockStoresManager = MockupStatsVersionStoresManager(initialStatsVersionLastShown: .v4,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = true
        ServiceLocator.setStores(mockStoresManager)

        let expectedStates: [StatsVersionState] = [.initial(statsVersion: .v4), .eligible(statsVersion: .v4)]
        let expectation = self.expectation(description: "Wait for states to match")
        expectation.expectedFulfillmentCount = 1

        var states: [StatsVersionState] = []
        let stateCoordinator = StatsVersionStateCoordinator(siteID: 134)
        stateCoordinator.onStateChange = { _, state in
            states.append(state)
            if states.count >= expectedStates.count {
                XCTAssertEqual(states, expectedStates)
                expectation.fulfill()
            }
        }
        stateCoordinator.loadLastShownVersionAndCheckV4Eligibility()
        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
