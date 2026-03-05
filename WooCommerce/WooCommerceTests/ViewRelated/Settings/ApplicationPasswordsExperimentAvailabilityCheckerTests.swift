import XCTest
import Yosemite
@testable import WooCommerce

final class ApplicationPasswordsExperimentAvailabilityCheckerTests: XCTestCase {
    private var availabilityChecker: ApplicationPasswordsExperimentAvailabilityCheckerProtocol!
    private var stores: MockStoresManager!
    private var userDefaults: UserDefaults!

    override func tearDown() {
        availabilityChecker = nil
        stores = nil
        userDefaults = nil
        super.tearDown()
    }

    private func setupEnvironment(
        isWPComAuthenticated: Bool,
        cachedRemoteFFEnabled: Bool
    ) throws {
        stores = MockStoresManager(
            sessionManager: .makeForTesting(
                authenticated: true,
                isWPCom: isWPComAuthenticated
            )
        )

        userDefaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        userDefaults[.applicationPasswordsExperimentRemoteFFValue] = cachedRemoteFFEnabled

        availabilityChecker = ApplicationPasswordsExperimentAvailabilityChecker(
            userDefaults: userDefaults,
            stores: stores
        )
    }

    func test_when_wpcom_authenticated_and_cached_remote_ff_enabled_then_isAvailable_returns_true() throws {
        try setupEnvironment(isWPComAuthenticated: true, cachedRemoteFFEnabled: true)
        XCTAssertTrue(availabilityChecker.isAvailable)
    }

    func test_when_wpcom_authenticated_and_cached_remote_ff_disabled_then_isAvailable_returns_false() throws {
        try setupEnvironment(isWPComAuthenticated: true, cachedRemoteFFEnabled: false)
        XCTAssertFalse(availabilityChecker.isAvailable)
    }

    func test_when_not_wpcom_authenticated_and_cached_remote_ff_enabled_then_isAvailable_returns_false() throws {
        try setupEnvironment(isWPComAuthenticated: false, cachedRemoteFFEnabled: true)
        XCTAssertFalse(availabilityChecker.isAvailable)
    }

    func test_when_not_wpcom_authenticated_and_cached_remote_ff_disabled_then_isAvailable_returns_false() throws {
        try setupEnvironment(isWPComAuthenticated: false, cachedRemoteFFEnabled: false)
        XCTAssertFalse(availabilityChecker.isAvailable)
    }

    @MainActor
    func test_when_cached_flag_is_disabled_and_remote_flag_is_enabled_then_fetchAvailability_returns_true() async throws {
        // Given
        stores = MockStoresManager(
            sessionManager: .makeForTesting(
                authenticated: true,
                isWPCom: true
            )
        )
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case .isRemoteFeatureFlagEnabled(_, _, _, let completion):
                completion(true)
            }
        }

        userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        userDefaults[.applicationPasswordsExperimentRemoteFFValue] = false

        availabilityChecker = ApplicationPasswordsExperimentAvailabilityChecker(
            userDefaults: userDefaults,
            stores: stores
        )

        // When
        let availability = await availabilityChecker.fetchAvailability()

        // Then
        XCTAssertTrue(availability)
    }

    @MainActor
    func test_when_cached_flag_is_enabled_and_remote_flag_is_disabled_then_fetchAvailability_returns_false() async throws {
        // Given
        stores = MockStoresManager(
            sessionManager: .makeForTesting(
                authenticated: true,
                isWPCom: true
            )
        )
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case .isRemoteFeatureFlagEnabled(_, _, _, let completion):
                completion(false)
            }
        }

        userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        userDefaults[.applicationPasswordsExperimentRemoteFFValue] = true

        availabilityChecker = ApplicationPasswordsExperimentAvailabilityChecker(
            userDefaults: userDefaults,
            stores: stores
        )

        // When
        let availability = await availabilityChecker.fetchAvailability()

        // Then
        XCTAssertFalse(availability)
    }
}
