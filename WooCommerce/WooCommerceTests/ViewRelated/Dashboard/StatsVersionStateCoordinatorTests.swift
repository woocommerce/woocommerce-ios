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
        mockStoresManager.statsVersionLastShown = nil
        mockStoresManager.isStatsV4Available = true
        ServiceLocator.setStores(mockStoresManager)

        // V3 is returned because it is the default value if `statsVersionLastShown` is `nil`
        let expectedStates: [StatsVersionState] = [.initial(statsVersion: .v3), .initial(statsVersion: .v4)]

        // When
        let actualStates = checkStatsVersionAndWait(expectedVersionChangesCount: expectedStates.count)

        // Then
        XCTAssertEqual(actualStates, expectedStates)
    }

    func testWhenV4IsUnavailableWhileNoStatsVersionWasShownBefore() {
        // Given
        mockStoresManager = MockupStatsVersionStoresManager(sessionManager: SessionManager.testingInstance)
        mockStoresManager.statsVersionLastShown = nil
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)

        // We will only receive one change because the stats-check should return the same value.
        let expectedStates: [StatsVersionState] = [.initial(statsVersion: .v3)]

        // When
        let actualStates = checkStatsVersionAndWait(expectedVersionChangesCount: expectedStates.count)

        // Then
        XCTAssertEqual(actualStates, expectedStates)
    }

    /// Stats v3 --> v4
    func testWhenV4IsAvailableWhileStatsV3IsLastShown() {
        // Given
        mockStoresManager = MockupStatsVersionStoresManager(initialStatsVersionLastShown: .v3,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = true
        ServiceLocator.setStores(mockStoresManager)

        let expectedStates: [StatsVersionState] = [.initial(statsVersion: .v3), .initial(statsVersion: .v4)]

        // When
        let actualStates = checkStatsVersionAndWait(expectedVersionChangesCount: expectedStates.count)

        // Then
        XCTAssertEqual(actualStates, expectedStates)
    }

    /// Stats v3 --> v3
    func testWhenV4IsUnavailableWhileStatsV3IsLastShown() {
        // Given
        mockStoresManager = MockupStatsVersionStoresManager(initialStatsVersionLastShown: .v3,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)

        // We will only receive one change because the stats-check should return the same value.
        let expectedStates: [StatsVersionState] = [.initial(statsVersion: .v3)]

        // When
        let actualStates = checkStatsVersionAndWait(expectedVersionChangesCount: expectedStates.count)

        // Then
        XCTAssertEqual(actualStates, expectedStates)
    }

    /// Stats v4 --> v3
    func testWhenV4IsUnavailableWhileStatsV4IsLastShown() {
        // Given
        mockStoresManager = MockupStatsVersionStoresManager(initialStatsVersionLastShown: .v4,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)

        let expectedStates: [StatsVersionState] = [.initial(statsVersion: .v4), .initial(statsVersion: .v3)]

        // When
        let actualStates = checkStatsVersionAndWait(expectedVersionChangesCount: expectedStates.count)

        // Then
        XCTAssertEqual(actualStates, expectedStates)
    }

    /// V4 --> v4
    func testWhenV4IsAvailableWhileStatsV4IsLastShown() {
        // Given
        mockStoresManager = MockupStatsVersionStoresManager(initialStatsVersionLastShown: .v4,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = true
        ServiceLocator.setStores(mockStoresManager)

        // We will only receive one change because the stats-check should return the same value.
        let expectedStates: [StatsVersionState] = [.initial(statsVersion: .v4)]

        // When
        let actualStates = checkStatsVersionAndWait(expectedVersionChangesCount: expectedStates.count)

        // Then
        XCTAssertEqual(actualStates, expectedStates)
    }
}

private extension StatsVersionStateCoordinatorTests {
    /// Execute `loadLastShownVersionAndCheckV4Eligibility` and wait for the results
    /// until the number of states defined by `expectedVersionChangesCount` is reached.
    ///
    func checkStatsVersionAndWait(expectedVersionChangesCount: Int) -> [StatsVersion] {
        var versions: [StatsVersion] = []

        waitForExpectation(timeout: 1.0) { exp in
            let stateCoordinator = StatsVersionStateCoordinator(siteID: 134)
            stateCoordinator.onVersionChange = { _, currentVersion in
                versions.append(currentVersion)
                if versions.count >= expectedVersionChangesCount {
                    exp.fulfill()
                }
            }

            stateCoordinator.loadLastShownVersionAndCheckV4Eligibility()
        }

        return versions
    }
}
