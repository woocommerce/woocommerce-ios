import XCTest
import Storage
@testable import WooCommerce

final class BetaFeaturesTests: XCTestCase {
    var appSettings: GeneralAppSettingsStorage!

    override func setUpWithError() throws {
        appSettings = GeneralAppSettingsStorage.init(fileStorage: MockInMemoryStorage())
    }

    override func tearDownWithError() throws {
        appSettings = nil
    }

    func test_viewAddons_defaults_to_false() {
        let enabled = appSettings.betaFeatureEnabled(.viewAddOns)
        XCTAssertEqual(enabled, false)
    }

    func test_viewAddons_defaults_saves_value() throws {
        try appSettings.setBetaFeatureEnabled(.viewAddOns, enabled: true)
        let enabled = appSettings.betaFeatureEnabled(.viewAddOns)
        XCTAssertEqual(enabled, true)
    }

    func test_viewAddons_binding_reads_and_writes_value() {
        let enabledBinding = appSettings.betaFeatureEnabledBinding(.viewAddOns)
        XCTAssertEqual(enabledBinding.wrappedValue, false)
        enabledBinding.wrappedValue = true
        let enabled = appSettings.betaFeatureEnabled(.viewAddOns)
        XCTAssertEqual(enabled, true)
    }
}
