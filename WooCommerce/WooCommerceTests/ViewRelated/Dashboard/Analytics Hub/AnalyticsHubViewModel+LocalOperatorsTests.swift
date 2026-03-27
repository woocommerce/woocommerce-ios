import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class AnalyticsHubViewModelLocalOperatorsTests: XCTestCase {
    func test_view_model_is_restricted_when_operator_cannot_view_analytics() {
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: .fake()))
        let viewModel = AnalyticsHubViewModel(
            siteID: 1,
            timeZone: .current,
            statsTimeRange: .thisYear,
            usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter(analytics: WooAnalytics(analyticsProvider: MockAnalyticsProvider())),
            stores: stores,
            storage: MockStorageManager(),
            analytics: WooAnalytics(analyticsProvider: MockAnalyticsProvider()),
            localOperatorCapabilitiesProvider: MockLocalOperatorCapabilitiesProvider(
                isDeviceStaffModeEnabled: true,
                activeOperator: LocalOperatorProfile(displayName: "Cashier", role: .cashier),
                currentCapabilities: .cashier
            )
        )

        XCTAssertTrue(viewModel.isRestrictedAccess)
        XCTAssertTrue(viewModel.enabledCards.isEmpty)
    }
}

private final class MockLocalOperatorCapabilitiesProvider: LocalOperatorCapabilitiesProviding {
    let isDeviceStaffModeEnabled: Bool
    let activeOperator: LocalOperatorProfile?
    let currentCapabilities: LocalOperatorCapabilities

    init(isDeviceStaffModeEnabled: Bool, activeOperator: LocalOperatorProfile?, currentCapabilities: LocalOperatorCapabilities) {
        self.isDeviceStaffModeEnabled = isDeviceStaffModeEnabled
        self.activeOperator = activeOperator
        self.currentCapabilities = currentCapabilities
    }

    func canViewAnalytics() -> Bool {
        currentCapabilities.canViewAnalytics
    }

    func canAccessAdminSettings() -> Bool {
        currentCapabilities.canAccessAdminSettings
    }

    func canManageLocalOperators() -> Bool {
        currentCapabilities.canManageLocalOperators
    }
}
