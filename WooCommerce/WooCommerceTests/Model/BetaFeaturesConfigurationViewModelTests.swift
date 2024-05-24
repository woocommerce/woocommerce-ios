import Combine
import Storage
import XCTest
@testable import WooCommerce

final class BetaFeaturesConfigurationViewModelTests: XCTestCase {
    private var appSettings: GeneralAppSettingsStorage!

    override func setUpWithError() throws {
        appSettings = GeneralAppSettingsStorage.init(fileStorage: MockInMemoryStorage())
    }

    override func tearDownWithError() throws {
        appSettings = nil
    }

    func test_availableFeatures_include_viewAddOns() {
        // Given
        let viewModel = BetaFeaturesConfigurationViewModel(appSettings: appSettings,
                                                           posEligibilityChecker: MockPOSEligibilityChecker(isEligibleValue: true))

        // Then
        XCTAssertTrue(viewModel.availableFeatures.contains(.viewAddOns))
    }

    func test_availableFeatures_include_pos_when_eligible_for_pos() {
        // Given
        let posEligibilityChecker = MockPOSEligibilityChecker(isEligibleValue: true)
        let viewModel = BetaFeaturesConfigurationViewModel(appSettings: appSettings, posEligibilityChecker: posEligibilityChecker)

        // Then
        XCTAssertTrue(viewModel.availableFeatures.contains(.pointOfSale))
    }

    func test_availableFeatures_do_not_include_pos_when_not_eligible_for_pos_anymore() {
        // Given
        let posEligibilityChecker = MockPOSEligibilityChecker(isEligibleValue: true)
        let viewModel = BetaFeaturesConfigurationViewModel(appSettings: appSettings, posEligibilityChecker: posEligibilityChecker)

        // When
        posEligibilityChecker.isEligibleValue = false

        // Then
        XCTAssertFalse(viewModel.availableFeatures.contains(.pointOfSale))
    }
}

private final class MockPOSEligibilityChecker: POSEligibilityCheckerProtocol {
    @Published var isEligibleValue: Bool

    init(isEligibleValue: Bool) {
        self.isEligibleValue = isEligibleValue
    }

    var isEligible: AnyPublisher<Bool, Never> {
        $isEligibleValue.eraseToAnyPublisher()
    }
}
