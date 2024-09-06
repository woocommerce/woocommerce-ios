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
