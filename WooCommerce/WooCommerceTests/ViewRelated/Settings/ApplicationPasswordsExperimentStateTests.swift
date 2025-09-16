import XCTest
import Yosemite
import Combine
@testable import WooCommerce

final class ApplicationPasswordsExperimentStateTests: XCTestCase {
    private var sut: ApplicationPasswordsExperimentState!
    private var availabilityChecker: ApplicationPasswordsExperimentAvailabilityCheckerMock!
    private var stores: MockStoresManager!
    private var cancellables: AnyCancellable?

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
        cancellables = nil
        super.tearDown()
    }

    func test_when_available_and_enabled_then_isAvailableAndEnabled_stream_returns_true() {
        // Given
        availabilityChecker.mockedAvailability = true
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let .getAppPasswordsExperimentSettingState(onCompletion) = action {
                onCompletion(true)
            }
        }

        // When
        var values: [Bool] = []
        cancellables = sut.$isAvailableAndEnabled
            .sink { result in
                values.append(result)
            }

        // Then
        waitUntil {
            values == [true, true]
        }
    }

    func test_when_available_and_disabled_then_isAvailableAndEnabled_stream_returns_false() {
        // Given
        availabilityChecker.mockedAvailability = true
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let .getAppPasswordsExperimentSettingState(onCompletion) = action {
                onCompletion(false)
            }
        }

        // When
        var values: [Bool] = []
        cancellables = sut.$isAvailableAndEnabled
            .sink { result in
                values.append(result)
            }

        // Then
        waitUntil {
            values == [true, false]
        }
    }

    func test_when_unavailable_and_enabled_then_isAvailableAndEnabled_stream_returns_false() {
        // Given
        availabilityChecker.mockedAvailability = false
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let .getAppPasswordsExperimentSettingState(onCompletion) = action {
                onCompletion(true)
            }
        }

        // When
        var values: [Bool] = []
        cancellables = sut.$isAvailableAndEnabled
            .sink { result in
                values.append(result)
            }

        // Then
        waitUntil {
            values == [true, false]
        }
    }

    func test_when_unavailable_and_disabled_then_isAvailableAndEnabled_stream_returns_false() {
        // Given
        availabilityChecker.mockedAvailability = false
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let .getAppPasswordsExperimentSettingState(onCompletion) = action {
                onCompletion(false)
            }
        }

        // When
        var values: [Bool] = []
        cancellables = sut.$isAvailableAndEnabled
            .sink { result in
                values.append(result)
            }

        // Then
        waitUntil {
            values == [true, false]
        }
    }
}

private final class ApplicationPasswordsExperimentAvailabilityCheckerMock: ApplicationPasswordsExperimentAvailabilityCheckerProtocol {
    var mockedAvailability = false

    var isAvailable: Bool {
        mockedAvailability
    }

    func fetchAvailability() async -> Bool {
        mockedAvailability
    }
}
