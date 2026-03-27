import XCTest
@testable import WooCommerce

@MainActor
final class LocalOperatorSessionControllerTests: XCTestCase {
    func test_unlock_sets_active_operator_when_pin_matches() throws {
        let store = MockLocalOperatorStore()
        let pinService = MockPINVerificationService()
        let profile = LocalOperatorProfile(displayName: "Alice", role: .manager)
        store.profiles = [profile]
        store.settings = .init(isDeviceStaffModeEnabled: true, inactivityTimeout: 300)
        try pinService.storePIN("1234", for: profile.pinReference)

        let sut = LocalOperatorSessionController(
            store: store,
            pinVerificationService: pinService,
            notificationCenter: NotificationCenter()
        )

        XCTAssertTrue(sut.unlock(operatorID: profile.id, pin: "1234"))
        XCTAssertEqual(sut.activeOperator?.displayName, "Alice")
        XCTAssertFalse(sut.isLocked)
    }

    func test_cashier_capabilities_disable_analytics_and_admin_settings() throws {
        let store = MockLocalOperatorStore()
        let pinService = MockPINVerificationService()
        let profile = LocalOperatorProfile(displayName: "Casey", role: .cashier)
        store.profiles = [profile]
        store.settings = .init(isDeviceStaffModeEnabled: true, inactivityTimeout: 300)
        try pinService.storePIN("1234", for: profile.pinReference)

        let sut = LocalOperatorSessionController(
            store: store,
            pinVerificationService: pinService,
            notificationCenter: NotificationCenter()
        )
        _ = sut.unlock(operatorID: profile.id, pin: "1234")

        XCTAssertFalse(sut.canViewAnalytics())
        XCTAssertFalse(sut.canAccessAdminSettings())
        XCTAssertFalse(sut.canManageLocalOperators())
        XCTAssertTrue(sut.currentCapabilities.canCreateOrders)
    }

    func test_bootstrap_manager_enables_unlockable_profile() throws {
        let store = MockLocalOperatorStore()
        store.settings = .init(isDeviceStaffModeEnabled: true, inactivityTimeout: 300)
        let pinService = MockPINVerificationService()
        let sut = LocalOperatorSessionController(
            store: store,
            pinVerificationService: pinService,
            notificationCenter: NotificationCenter()
        )

        try sut.bootstrapManager(displayName: "Manager", pin: "1234")

        XCTAssertEqual(sut.profiles.count, 1)
        XCTAssertEqual(sut.activeOperator?.role, .manager)
        XCTAssertFalse(sut.requiresBootstrap)
        XCTAssertFalse(sut.isLocked)
    }

    func test_register_activity_locks_session_after_timeout() throws {
        let store = MockLocalOperatorStore()
        let pinService = MockPINVerificationService()
        let profile = LocalOperatorProfile(displayName: "Taylor", role: .manager)
        store.profiles = [profile]
        store.settings = .init(isDeviceStaffModeEnabled: true, inactivityTimeout: 0.1)
        try pinService.storePIN("1234", for: profile.pinReference)

        let sut = LocalOperatorSessionController(
            store: store,
            pinVerificationService: pinService,
            notificationCenter: NotificationCenter()
        )

        XCTAssertTrue(sut.unlock(operatorID: profile.id, pin: "1234"))
        XCTAssertFalse(sut.isLocked)

        let expectation = XCTestExpectation(description: "session locks after inactivity timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(sut.isLocked)
        XCTAssertNil(sut.activeOperator)
    }

    func test_delete_active_operator_locks_and_requires_bootstrap_when_last_operator_removed() throws {
        let store = MockLocalOperatorStore()
        let pinService = MockPINVerificationService()
        let profile = LocalOperatorProfile(displayName: "Morgan", role: .manager)
        store.profiles = [profile]
        store.settings = .init(isDeviceStaffModeEnabled: true, inactivityTimeout: 300)
        try pinService.storePIN("1234", for: profile.pinReference)

        let sut = LocalOperatorSessionController(
            store: store,
            pinVerificationService: pinService,
            notificationCenter: NotificationCenter()
        )

        XCTAssertTrue(sut.unlock(operatorID: profile.id, pin: "1234"))

        sut.deleteOperator(profile)

        XCTAssertTrue(sut.profiles.isEmpty)
        XCTAssertTrue(sut.isLocked)
        XCTAssertTrue(sut.requiresBootstrap)
        XCTAssertNil(sut.activeOperator)
    }
}

private final class MockLocalOperatorStore: LocalOperatorStoreProtocol {
    var settings: LocalOperatorSettings = .default
    var profiles: [LocalOperatorProfile] = []

    func loadProfiles() -> [LocalOperatorProfile] {
        profiles
    }

    func saveProfiles(_ profiles: [LocalOperatorProfile]) {
        self.profiles = profiles
    }
}

private final class MockPINVerificationService: PINVerificationServiceProtocol {
    private var storedPins: [String: String] = [:]

    func storePIN(_ pin: String, for reference: String) throws {
        storedPins[reference] = pin
    }

    func verifyPIN(_ pin: String, for reference: String) -> Bool {
        storedPins[reference] == pin
    }

    func deletePIN(for reference: String) {
        storedPins[reference] = nil
    }
}
