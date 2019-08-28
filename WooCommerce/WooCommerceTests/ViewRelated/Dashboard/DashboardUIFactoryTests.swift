import XCTest
import Storage
import Yosemite
@testable import WooCommerce

final class DashboardUIFactoryTests: XCTestCase {
    private let mockSiteID: Int = 1134

    private var dashboardUIFactory: DashboardUIFactory!
    private var mockStoresManager: MockupStatsVersionStoresManager!

    override func tearDown() {
        dashboardUIFactory = nil
        mockStoresManager = nil
        super.tearDown()
    }

    func testStatsVersionWhenFeatureFlagIsOff() {
        mockStoresManager = MockupStatsVersionStoresManager(sessionManager: SessionManager.testingInstance)
        ServiceLocator.setStores(mockStoresManager)
        dashboardUIFactory = DashboardUIFactory(siteID: mockSiteID)

        let expectation = self.expectation(description: "Wait for the initial stats version")

        dashboardUIFactory.reloadDashboardUI(isFeatureFlagOn: false) { dashboardUI in
            XCTAssertTrue(dashboardUI is DashboardStatsV3ViewController)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testWhenV4IsAvailableWhileNoStatsVersionIsSaved() {
        mockStoresManager = MockupStatsVersionStoresManager(sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = true
        ServiceLocator.setStores(mockStoresManager)

        dashboardUIFactory = DashboardUIFactory(siteID: mockSiteID)

        var dashboardUITypes: [UIViewController.Type] = []
        let expectedDashboardUITypes: [UIViewController.Type] = [DashboardStatsV3ViewController.self, StoreStatsAndTopPerformersViewController.self]
        let expectation = self.expectation(description: "Wait for the stats v4")
        expectation.expectedFulfillmentCount = 1

        dashboardUIFactory.reloadDashboardUI(isFeatureFlagOn: true) { dashboardUI in
            dashboardUITypes.append(type(of: dashboardUI))
            if dashboardUITypes.count >= expectedDashboardUITypes.count {
                for i in 0..<dashboardUITypes.count {
                    XCTAssertTrue(dashboardUITypes[i] == expectedDashboardUITypes[i])
                }
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testWhenV4IsUnavailableWhileNoStatsVersionIsSaved() {
        mockStoresManager = MockupStatsVersionStoresManager(sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)

        dashboardUIFactory = DashboardUIFactory(siteID: mockSiteID)

        var dashboardUIArray: [DashboardUI] = []
        let expectation = self.expectation(description: "Wait for the stats v4")
        expectation.expectedFulfillmentCount = 1

        dashboardUIFactory.reloadDashboardUI(isFeatureFlagOn: true) { dashboardUI in
            dashboardUIArray.append(dashboardUI)
            // 2 view controllers are expected to be the same v3 UI.
            if dashboardUIArray.count >= 2 {
                XCTAssertTrue(dashboardUIArray[0] == dashboardUIArray[1])
                XCTAssertTrue(dashboardUIArray[0] is DashboardStatsV3ViewController)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    /// Stats v3 --> v3
    func testWhenV4IsUnavailableWhileStatsV3IsLastShown() {
        mockStoresManager = MockupStatsVersionStoresManager(initialStatsVersionLastShown: .v3,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)

        dashboardUIFactory = DashboardUIFactory(siteID: mockSiteID)

        var dashboardUIArray: [DashboardUI] = []
        let expectation = self.expectation(description: "Wait for the stats v4")
        expectation.expectedFulfillmentCount = 1

        dashboardUIFactory.reloadDashboardUI(isFeatureFlagOn: true) { dashboardUI in
            dashboardUIArray.append(dashboardUI)
            // 2 view controllers are expected to be the same v3 UI.
            if dashboardUIArray.count >= 2 {
                XCTAssertTrue(dashboardUIArray[0] == dashboardUIArray[1])
                XCTAssertTrue(dashboardUIArray[0] is DashboardStatsV3ViewController)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    /// Stats v4 --> v4
    func testWhenV4IsAvailableWhileStatsV4IsLastShown() {
        mockStoresManager = MockupStatsVersionStoresManager(initialStatsVersionLastShown: .v4,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = true
        ServiceLocator.setStores(mockStoresManager)

        dashboardUIFactory = DashboardUIFactory(siteID: mockSiteID)

        var dashboardUIArray: [DashboardUI] = []
        let expectation = self.expectation(description: "Wait for the stats v4")
        expectation.expectedFulfillmentCount = 1

        dashboardUIFactory.reloadDashboardUI(isFeatureFlagOn: true) { dashboardUI in
            dashboardUIArray.append(dashboardUI)
            // 2 view controllers are expected to be the same v4 UI.
            if dashboardUIArray.count >= 2 {
                XCTAssertTrue(dashboardUIArray[0] == dashboardUIArray[1])
                XCTAssertTrue(dashboardUIArray[0] is StoreStatsAndTopPerformersViewController)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
