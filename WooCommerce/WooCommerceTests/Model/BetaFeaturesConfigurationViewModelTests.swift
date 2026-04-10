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
        let viewModel = BetaFeaturesConfigurationViewModel(appSettings: appSettings)

        // Then
        XCTAssertTrue(viewModel.availableFeatures.contains(.viewAddOns))
    }
}
