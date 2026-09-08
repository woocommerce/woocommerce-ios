import Combine
import Storage
import XCTest
@testable import WooCommerce

final class BetaFeaturesConfigurationViewModelTests: XCTestCase {
    private var appSettings: GeneralAppSettingsStorage!

    override func setUpWithError() throws {
        appSettings = GeneralAppSettingsStorage(fileStorage: MockInMemoryStorage())
    }

    override func tearDownWithError() throws {
        appSettings = nil
    }

    func test_availableFeatures_include_viewAddOns() {
        // Given
        let viewModel = BetaFeaturesConfigurationViewModel(appSettings: appSettings,
                                                           isPOSTabVisible: { false })

        // Then
        XCTAssertTrue(viewModel.availableFeatures.contains(.viewAddOns))
    }

    func test_availableFeatures_include_posLocalCatalog_when_POSTab_is_visible() async {
        // Given
        let viewModel = BetaFeaturesConfigurationViewModel(appSettings: appSettings,
                                                           isPOSTabVisible: { true })

        // When
        await viewModel.refreshAvailableFeatures()

        // Then
        XCTAssertTrue(viewModel.availableFeatures.contains(.posLocalCatalog))
    }

    func test_availableFeatures_do_not_include_posLocalCatalog_when_POSTab_is_not_visible() async {
        // Given
        let viewModel = BetaFeaturesConfigurationViewModel(appSettings: appSettings,
                                                           isPOSTabVisible: { false })

        // When
        await viewModel.refreshAvailableFeatures()

        // Then
        XCTAssertFalse(viewModel.availableFeatures.contains(.posLocalCatalog))
    }
}
