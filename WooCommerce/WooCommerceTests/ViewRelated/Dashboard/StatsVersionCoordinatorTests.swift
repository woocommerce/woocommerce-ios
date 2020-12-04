import XCTest
import Storage
import Yosemite
@testable import WooCommerce

final class StatsVersionCoordinatorTests: XCTestCase {
    private var mockStoresManager: MockStatsVersionStoresManager!

    override func tearDown() {
        mockStoresManager = nil
        super.tearDown()
    }

    func test_it_returns_v4_version_when_V4_is_available_while_no_stats_version_was_shown_before() {
        // Given
        mockStoresManager = MockStatsVersionStoresManager(sessionManager: SessionManager.testingInstance)
        mockStoresManager.statsVersionLastShown = nil
        mockStoresManager.isStatsV4Available = true
        ServiceLocator.setStores(mockStoresManager)

        // V4 is returned because it is the default value if `statsVersionLastShown` is `nil`
        let expectedVersions: [StatsVersion] = [.v4]

        // When
        let actualVersions = checkStatsVersionAndWait(expectedVersionChangesCount: expectedVersions.count)

        // Then
        XCTAssertEqual(actualVersions, expectedVersions)
    }

    func test_it_transition_from_v4_to_v3_when_V4_is_unavailable_while_no_stats_version_was_shown_before() {
        // Given
        mockStoresManager = MockStatsVersionStoresManager(sessionManager: SessionManager.testingInstance)
        mockStoresManager.statsVersionLastShown = nil
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)

        // Initial value is `.v4` when `statsVersionLastShown` is `nil`
        let expectedVersions: [StatsVersion] = [.v4, .v3]

        // When
        let actualVersions = checkStatsVersionAndWait(expectedVersionChangesCount: expectedVersions.count)

        // Then
        XCTAssertEqual(actualVersions, expectedVersions)
    }

    /// Stats v3 --> v4
    func test_when_V4_is_available_while_stats_V3_is_last_shown() {
        // Given
        mockStoresManager = MockStatsVersionStoresManager(initialStatsVersionLastShown: .v3,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = true
        ServiceLocator.setStores(mockStoresManager)

        let expectedVersions: [StatsVersion] = [.v3, .v4]

        // When
        let actualVersions = checkStatsVersionAndWait(expectedVersionChangesCount: expectedVersions.count)

        // Then
        XCTAssertEqual(actualVersions, expectedVersions)
    }

    /// Stats v3 --> v3
    func test_when_V4_is_unavailable_while_stats_V3_is_last_shown() {
        // Given
        mockStoresManager = MockStatsVersionStoresManager(initialStatsVersionLastShown: .v3,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)

        // We will only receive one change because the stats-check should return the same value.
        let expectedVersions: [StatsVersion] = [.v3]

        // When
        let actualVersions = checkStatsVersionAndWait(expectedVersionChangesCount: expectedVersions.count)

        // Then
        XCTAssertEqual(actualVersions, expectedVersions)
    }

    /// Stats v4 --> v3
    func test_when_V4_is_unavailable_while_stats_V4_is_last_shown() {
        // Given
        mockStoresManager = MockStatsVersionStoresManager(initialStatsVersionLastShown: .v4,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)

        let expectedVersions: [StatsVersion] = [.v4, .v3]

        // When
        let actualVersions = checkStatsVersionAndWait(expectedVersionChangesCount: expectedVersions.count)

        // Then
        XCTAssertEqual(actualVersions, expectedVersions)
    }

    /// V4 --> v4
    func test_when_V4_is_available_while_stats_V4_is_last_shown() {
        // Given
        mockStoresManager = MockStatsVersionStoresManager(initialStatsVersionLastShown: .v4,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = true
        ServiceLocator.setStores(mockStoresManager)

        // We will only receive one change because the stats-check should return the same value.
        let expectedVersions: [StatsVersion] = [.v4]

        // When
        let actualVersions = checkStatsVersionAndWait(expectedVersionChangesCount: expectedVersions.count)

        // Then
        XCTAssertEqual(actualVersions, expectedVersions)
    }
}

private extension StatsVersionCoordinatorTests {
    /// Execute `loadLastShownVersionAndCheckV4Eligibility` and wait for the results
    /// until the number of states defined by `expectedVersionChangesCount` is reached.
    ///
    func checkStatsVersionAndWait(expectedVersionChangesCount: Int) -> [StatsVersion] {
        var versions: [StatsVersion] = []

        waitForExpectation(timeout: 1.0) { exp in
            let versionCoordinator = StatsVersionCoordinator(siteID: 134)
            versionCoordinator.onVersionChange = { _, currentVersion in
                versions.append(currentVersion)
                if versions.count >= expectedVersionChangesCount {
                    exp.fulfill()
                }
            }

            versionCoordinator.loadLastShownVersionAndCheckV4Eligibility()
        }

        return versions
    }
}
