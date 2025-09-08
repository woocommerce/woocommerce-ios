import XCTest
import Yosemite
@testable import WooCommerce

final class ApplicationPasswordsExperimentAvailabilityCheckerTests: XCTestCase {
    private var availabilityChecker: ApplicationPasswordsExperimentAvailabilityCheckerProtocol!
    private var stores: StoresManager!
    private var userDefaults: UserDefaults!

    override func tearDown() {
        availabilityChecker = nil
        stores = nil
        userDefaults = nil
        super.tearDown()
    }

    private func setupEnvironment(
        isWPComAuthenticated: Bool,
        isRemoteFFEnabled: Bool
    ) throws {
        stores = MockStoresManager(
            sessionManager: .makeForTesting(
                authenticated: true,
                isWPCom: isWPComAuthenticated
            )
        )

        userDefaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        userDefaults[.applicationPasswordsExperimentRemoteFFValue] = isRemoteFFEnabled

        availabilityChecker = ApplicationPasswordsExperimentAvailabilityChecker(
            userDefaults: userDefaults,
            stores: stores
        )
    }

    func test_when_wpcom_authenticated_and_remote_ff_enabled_then_isAvailable_returns_true() throws {
        try setupEnvironment(isWPComAuthenticated: true, isRemoteFFEnabled: true)
        XCTAssertTrue(availabilityChecker.isAvailable)
    }

    func test_when_wpcom_authenticated_and_remote_ff_disabled_then_isAvailable_returns_false() throws {
        try setupEnvironment(isWPComAuthenticated: true, isRemoteFFEnabled: false)
        XCTAssertFalse(availabilityChecker.isAvailable)
    }

    func test_when_not_wpcom_authenticated_and_remote_ff_enabled_then_isAvailable_returns_false() throws {
        try setupEnvironment(isWPComAuthenticated: false, isRemoteFFEnabled: true)
        XCTAssertFalse(availabilityChecker.isAvailable)
    }

    func test_when_not_wpcom_authenticated_and_remote_ff_disabled_then_isAvailable_returns_false() throws {
        try setupEnvironment(isWPComAuthenticated: false, isRemoteFFEnabled: false)
        XCTAssertFalse(availabilityChecker.isAvailable)
    }
}
