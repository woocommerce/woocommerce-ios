import XCTest
import Storage
import Yosemite
@testable import WooCommerce

final class DashboardUIFactoryTests: XCTestCase {
    private let mockSiteID: Int64 = 1134

    private var dashboardUIFactory: DashboardUIFactory!
    private var mockStoresManager: MockupStatsVersionStoresManager!

    override func tearDown() {
        dashboardUIFactory = nil
        mockStoresManager = nil
        super.tearDown()
    }

    func test_it_loads_only_statsV4_when_V4_is_available_while_no_stats_version_is_saved() {
        // Given
        mockStoresManager = MockupStatsVersionStoresManager(sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = true
        ServiceLocator.setStores(mockStoresManager)
        dashboardUIFactory = DashboardUIFactory(siteID: mockSiteID)

        // When
        var dashboard: DashboardUI?
        waitForExpectation { exp in
            dashboardUIFactory.reloadDashboardUI { dashboardUI in
                dashboard = dashboardUI
                exp.fulfill()
            }
        }

        // Then
        XCTAssertTrue(dashboard is StoreStatsAndTopPerformersViewController)
    }

    func test_it_loads_deprecated_dashboard_when_V4_is_unavailable_while_no_stats_version_is_saved() {
        // Given
        mockStoresManager = MockupStatsVersionStoresManager(sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)
        dashboardUIFactory = DashboardUIFactory(siteID: mockSiteID)

        // When
        var dashboardUITypes: [UIViewController.Type] = []
        let expectedDashboardUITypes: [UIViewController.Type] = [StoreStatsAndTopPerformersViewController.self,
                                                                 DeprecatedDashboardStatsViewController.self]

        waitForExpectation(description: #function, count: expectedDashboardUITypes.count) { exp in
            dashboardUIFactory.reloadDashboardUI { dashboardUI in
                dashboardUITypes.append(type(of: dashboardUI))
                exp.fulfill()
            }
        }

        // Then
        XCTAssertEqual(dashboardUITypes.count, expectedDashboardUITypes.count)
        XCTAssertTrue(dashboardUITypes[0] == expectedDashboardUITypes[0])
        XCTAssertTrue(dashboardUITypes[1] == expectedDashboardUITypes[1])
    }

    /// Stats v4 --> v4
    func test_when_V4_is_available_while_stats_V4_is_last_shown() {
        mockStoresManager = MockupStatsVersionStoresManager(initialStatsVersionLastShown: .v4,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = true
        ServiceLocator.setStores(mockStoresManager)

        dashboardUIFactory = DashboardUIFactory(siteID: mockSiteID)

        let expectation = self.expectation(description: "Wait for the stats v4")
        expectation.expectedFulfillmentCount = 1

        dashboardUIFactory.reloadDashboardUI { dashboardUI in
            XCTAssertTrue(dashboardUI is StoreStatsAndTopPerformersViewController)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    /// Stats v4 --> v3 --> v4
    func test_when_V4_is_unavailable_and_then_available_while_stats_v4_is_last_shown() {
        mockStoresManager = MockupStatsVersionStoresManager(initialStatsVersionLastShown: .v4,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)

        dashboardUIFactory = DashboardUIFactory(siteID: mockSiteID)

        var dashboardUIArray: [DashboardUI] = []
        let expectation = self.expectation(description: "Wait for the stats v4")
        expectation.expectedFulfillmentCount = 1

        dashboardUIFactory.reloadDashboardUI { [weak self] dashboardUI in
            dashboardUIArray.append(dashboardUI)
            // The first updated view controller is v4, and the second view controller is reverted back to v3.
            if dashboardUIArray.count >= 2 {
                XCTAssertTrue(dashboardUIArray[0] is StoreStatsAndTopPerformersViewController)
                XCTAssertTrue(dashboardUIArray[1] is DeprecatedDashboardStatsViewController)

                guard let self = self else {
                    XCTFail()
                    return
                }
                // Stats v4 now becomes available
                self.mockStoresManager.isStatsV4Available = true
                dashboardUIArray = []

                self.dashboardUIFactory.reloadDashboardUI { dashboardUI in
                    dashboardUIArray.append(dashboardUI)

                    // The first view controller is v4 -> v3 UI, and the second view controller is v3 -> v4 UI.
                    if dashboardUIArray.count >= 2 {
                        XCTAssertTrue(dashboardUIArray[0] is DeprecatedDashboardStatsViewController)
                        XCTAssertTrue(dashboardUIArray[1] is StoreStatsAndTopPerformersViewController)
                        expectation.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_deprecated_stats_screen_is_shown_if_V4_is_unavailable() {
        // Given
        mockStoresManager = MockupStatsVersionStoresManager(initialStatsVersionLastShown: .v3,
                                                            sessionManager: SessionManager.testingInstance)
        mockStoresManager.isStatsV4Available = false
        ServiceLocator.setStores(mockStoresManager)
        dashboardUIFactory = DashboardUIFactory(siteID: mockSiteID)

        // When
        let exp = self.expectation(description: #function)
        var renderedDashboard: DashboardUI?
        dashboardUIFactory.reloadDashboardUI { dashboardUI in
            renderedDashboard = dashboardUI
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)

        //Then
        XCTAssertTrue(renderedDashboard is DeprecatedDashboardStatsViewController)
    }
}
