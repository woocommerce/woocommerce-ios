import XCTest
import Storage
import Yosemite
@testable import WooCommerce

/// MockupAvailabilityStoreManager: allows mocking for stats v4 availability.
///
private class MockupAvailabilityStoreManager: DefaultStoresManager {

    /// Indicates if stats v4 is available.
    ///
    var isStatsV4Available = false

    /// Set by setter `AppSettingsAction`.
    ///
    private var statsVersionLastShown: StatsVersion?

    // MARK: - Overridden Methods

    override func dispatch(_ action: Action) {
        if let availabilityAction = action as? AvailabilityAction {
            onAvailabilityAction(action: availabilityAction)
        } else if let appSettingsAction = action as? AppSettingsAction {
            onAppSettingsAction(action: appSettingsAction)
        } else {
            super.dispatch(action)
        }
    }

    private func onAvailabilityAction(action: AvailabilityAction) {
        switch action {
        case .checkStatsV4Availability(_,
                                       let onCompletion):
            onCompletion(isStatsV4Available)
        }
    }

    private func onAppSettingsAction(action: AppSettingsAction) {
        switch action {
        case .loadStatsVersionLastShown(_, let onCompletion):
            onCompletion(statsVersionLastShown)
        case .setStatsVersionLastShown(_, let statsVersion):
            statsVersionLastShown = statsVersion
        default:
            return
        }
    }
}

class DashboardUIFactoryTests: XCTestCase {
    private let mockSiteID: Int = 1134

    private var mockStoresManager: MockupAvailabilityStoreManager!

    override func setUp() {
        super.setUp()
        mockStoresManager = MockupAvailabilityStoreManager(sessionManager: SessionManager.testingInstance)
    }

    func testStatsVersionWhenFeatureFlagIsOff() {
        let expectation = self.expectation(description: "Wait for the initial stats version")
        DashboardUIFactory.dashboardUIStatsVersion(isFeatureFlagOn: false,
                                                   siteID: mockSiteID,
                                                   onInitialUI: { initialStatsVersion in
                                                    XCTAssertEqual(initialStatsVersion, .v3)
                                                    expectation.fulfill()
        }, onUpdate: { updatedStatsVersion in
            XCTFail("There should not be any update when feature flag is off")
        })
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testStatsVersionWhenV4IsAvailableWhileNoStatsVersionIsSaved() {
        ServiceLocator.setStores(mockStoresManager)
        mockStoresManager.isStatsV4Available = true

        let expectationForInitialVerion = expectation(description: "Wait for the initial stats version")
        let expectationForUpdatedVerion = expectation(description: "Wait for the updated stats version")
        DashboardUIFactory.dashboardUIStatsVersion(isFeatureFlagOn: true,
                                                   siteID: mockSiteID,
                                                   onInitialUI: { initialStatsVersion in
                                                    // When no stats version is saved before, v3 should be shown.
                                                    XCTAssertEqual(initialStatsVersion, .v3)
                                                    expectationForInitialVerion.fulfill()
        }, onUpdate: { updatedStatsVersion in
            XCTAssertEqual(updatedStatsVersion, .v4)
            expectationForUpdatedVerion.fulfill()
        })
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    /// Stats v3 --> v4
    func testStatsVersionWhenV4IsAvailableWhileStatsV3IsLastShown() {
        ServiceLocator.setStores(mockStoresManager)
        mockStoresManager.isStatsV4Available = true

        let lastSeenStatsVersion = StatsVersion.v3
        _ = DashboardUIFactory.createDashboardUIAndSetUserPreference(siteID: mockSiteID, statsVersion: lastSeenStatsVersion)

        let expectationForInitialVerion = expectation(description: "Wait for the initial stats version")
        let expectationForUpdatedVerion = expectation(description: "Wait for the updated stats version")
        DashboardUIFactory.dashboardUIStatsVersion(isFeatureFlagOn: true,
                                                   siteID: mockSiteID,
                                                   onInitialUI: { initialStatsVersion in
                                                    XCTAssertEqual(initialStatsVersion, lastSeenStatsVersion)
                                                    expectationForInitialVerion.fulfill()
        }, onUpdate: { updatedStatsVersion in
            XCTAssertEqual(updatedStatsVersion, .v4)
            expectationForUpdatedVerion.fulfill()
        })
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    /// Stats v3 --> v3
    func testStatsVersionWhenV4IsUnavailableWhileStatsV3IsLastShown() {
        ServiceLocator.setStores(mockStoresManager)
        mockStoresManager.isStatsV4Available = false

        let lastSeenStatsVersion = StatsVersion.v3
        _ = DashboardUIFactory.createDashboardUIAndSetUserPreference(siteID: mockSiteID, statsVersion: lastSeenStatsVersion)

        let expectationForInitialVerion = expectation(description: "Wait for the initial stats version")
        DashboardUIFactory.dashboardUIStatsVersion(isFeatureFlagOn: true,
                                                   siteID: mockSiteID,
                                                   onInitialUI: { initialStatsVersion in
                                                    XCTAssertEqual(initialStatsVersion, lastSeenStatsVersion)
                                                    expectationForInitialVerion.fulfill()
        }, onUpdate: { updatedStatsVersion in
            XCTFail("onUpdate should not be called when the version is the same")
        })
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    /// Stats v4 --> v3
    func testStatsVersionWhenV4IsUnavailableWhileStatsV4IsLastShown() {
        ServiceLocator.setStores(mockStoresManager)
        mockStoresManager.isStatsV4Available = false

        let lastSeenStatsVersion = StatsVersion.v4
        _ = DashboardUIFactory.createDashboardUIAndSetUserPreference(siteID: mockSiteID, statsVersion: lastSeenStatsVersion)

        let expectationForInitialVerion = expectation(description: "Wait for the initial stats version")
        let expectationForUpdatedVerion = expectation(description: "Wait for the updated stats version")
        DashboardUIFactory.dashboardUIStatsVersion(isFeatureFlagOn: true,
                                                   siteID: mockSiteID,
                                                   onInitialUI: { initialStatsVersion in
                                                    XCTAssertEqual(initialStatsVersion, lastSeenStatsVersion)
                                                    expectationForInitialVerion.fulfill()
        }, onUpdate: { updatedStatsVersion in
            XCTAssertEqual(updatedStatsVersion, .v3)
            expectationForUpdatedVerion.fulfill()
        })
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    /// V4 --> v4
    func testStatsVersionWhenV4IsAvailableWhileStatsV4IsLastShown() {
        ServiceLocator.setStores(mockStoresManager)
        mockStoresManager.isStatsV4Available = true

        let lastSeenStatsVersion = StatsVersion.v4
        _ = DashboardUIFactory.createDashboardUIAndSetUserPreference(siteID: mockSiteID, statsVersion: lastSeenStatsVersion)

        let expectationForInitialVerion = expectation(description: "Wait for the initial stats version")
        DashboardUIFactory.dashboardUIStatsVersion(isFeatureFlagOn: true,
                                                   siteID: mockSiteID,
                                                   onInitialUI: { initialStatsVersion in
                                                    XCTAssertEqual(initialStatsVersion, lastSeenStatsVersion)
                                                    expectationForInitialVerion.fulfill()
        }, onUpdate: { updatedStatsVersion in
            XCTFail("onUpdate should not be called when the version is the same")
        })
        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
