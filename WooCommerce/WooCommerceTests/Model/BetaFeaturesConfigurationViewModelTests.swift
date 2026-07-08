import Combine
import Experiments
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

    func test_availableFeatures_include_posLocalCatalog_when_catalogAPI_feature_flag_is_enabled_and_POSTab_is_visible() async {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleCatalogAPI] = true

        let viewModel = BetaFeaturesConfigurationViewModel(appSettings: appSettings,
                                                           featureFlagService: featureFlagService,
                                                           isPOSTabVisible: { true })

        // When
        await viewModel.refreshAvailableFeatures()

        // Then
        XCTAssertTrue(viewModel.availableFeatures.contains(.posLocalCatalog))
    }

    func test_availableFeatures_do_not_include_posLocalCatalog_when_POSTab_is_not_visible() async {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleCatalogAPI] = true

        let viewModel = BetaFeaturesConfigurationViewModel(appSettings: appSettings,
                                                           featureFlagService: featureFlagService,
                                                           isPOSTabVisible: { false })

        // When
        await viewModel.refreshAvailableFeatures()

        // Then
        XCTAssertFalse(viewModel.availableFeatures.contains(.posLocalCatalog))
    }

    func test_availableFeatures_do_not_include_posLocalCatalog_when_catalogAPI_feature_flag_is_disabled() async {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleCatalogAPI] = false
        let posTabVisibility = POSTabVisibilitySpy(isVisible: true)

        let viewModel = BetaFeaturesConfigurationViewModel(appSettings: appSettings,
                                                           featureFlagService: featureFlagService,
                                                           isPOSTabVisible: posTabVisibility.checkVisibility)

        // When
        await viewModel.refreshAvailableFeatures()

        // Then
        XCTAssertFalse(viewModel.availableFeatures.contains(.posLocalCatalog))
        XCTAssertFalse(posTabVisibility.didCheckVisibility)
    }
}

private final class POSTabVisibilitySpy {
    private let isVisible: Bool
    private(set) var didCheckVisibility = false

    init(isVisible: Bool) {
        self.isVisible = isVisible
    }

    func checkVisibility() async -> Bool {
        didCheckVisibility = true
        return isVisible
    }
}
