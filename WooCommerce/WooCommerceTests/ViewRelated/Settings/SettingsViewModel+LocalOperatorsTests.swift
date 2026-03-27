import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class SettingsViewModelLocalOperatorsTests: XCTestCase {
    func test_sections_hide_plugins_for_cashier_operator() {
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultRoles: [.administrator]))
        let capabilities = MockLocalOperatorCapabilitiesProvider(
            isDeviceStaffModeEnabled: true,
            activeOperator: LocalOperatorProfile(displayName: "Cashier", role: .cashier),
            currentCapabilities: .cashier
        )

        let viewModel = SettingsViewModel(
            stores: stores,
            storageManager: MockStorageManager(),
            localOperatorCapabilitiesProvider: capabilities
        )

        viewModel.onViewDidLoad()

        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(.plugins) })
        XCTAssertTrue(viewModel.sections.contains { $0.rows.contains(.switchOperator) })
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(.localOperators) })
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
