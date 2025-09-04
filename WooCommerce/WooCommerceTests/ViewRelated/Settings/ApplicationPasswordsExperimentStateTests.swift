import XCTest
import Yosemite
@testable import WooCommerce

final class ApplicationPasswordsExperimentStateTests: XCTestCase {
    private var sut: ApplicationPasswordsExperimentState!
    private var availabilityChecker: ApplicationPasswordsExperimentAvailabilityCheckerMock!
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        availabilityChecker = ApplicationPasswordsExperimentAvailabilityCheckerMock()
        stores = MockStoresManager(sessionManager: .makeForTesting())
        sut = ApplicationPasswordsExperimentState(stores: stores, availabilityChecker: availabilityChecker)
    }

    override func tearDown() {
        sut = nil
        availabilityChecker = nil
        stores = nil
        super.tearDown()
    }

    func test_when_available_and_enabled_then_isAvailableAndEnabled_returns_true() async {
        // Given
        availabilityChecker.mockedAvailability = true
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let .getAppPasswordsExperimentSettingState(onCompletion) = action {
                onCompletion(true)
            }
        }

        // When
        let result = await sut.isAvailableAndEnabled

        // Then
        XCTAssertTrue(result)
    }

    func test_when_available_and_disabled_then_isAvailableAndEnabled_returns_false() async {
        // Given
        availabilityChecker.mockedAvailability = true
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let .getAppPasswordsExperimentSettingState(onCompletion) = action {
                onCompletion(false)
            }
        }

        // When
        let result = await sut.isAvailableAndEnabled

        // Then
        XCTAssertFalse(result)
    }

    func test_when_unavailable_and_enabled_then_isAvailableAndEnabled_returns_false() async {
        // Given
        availabilityChecker.mockedAvailability = false
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let .getAppPasswordsExperimentSettingState(onCompletion) = action {
                onCompletion(true)
            }
        }

        // When
        let result = await sut.isAvailableAndEnabled

        // Then
        XCTAssertFalse(result)
    }

    func test_when_unavailable_and_disabled_then_isAvailableAndEnabled_returns_false() async {
        // Given
        availabilityChecker.mockedAvailability = false
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let .getAppPasswordsExperimentSettingState(onCompletion) = action {
                onCompletion(false)
            }
        }

        // When
        let result = await sut.isAvailableAndEnabled

        // Then
        XCTAssertFalse(result)
    }
}

private final class ApplicationPasswordsExperimentAvailabilityCheckerMock: ApplicationPasswordsExperimentAvailabilityCheckerProtocol {
    var mockedAvailability = false

    var cachedValue: Bool {
        mockedAvailability
    }

    func fetchAvailability() async -> Bool {
        mockedAvailability
    }
}
