import XCTest
@testable import WooCommerce

final class NewTaxRateSelectorViewModelTests: XCTestCase {
    func test_wpAdminTaxSettingsURL_passes_right_url() {
        // Given
        let wpAdminTaxSettingsURL = URL(string: "https://www.site.com/wp-admin/mock-taxes-settings")
        let wpAdminTaxSettingsURLProvider = MockWPAdminTaxSettingsURLProvider(wpAdminTaxSettingsURL: wpAdminTaxSettingsURL)

        let viewModel = NewTaxRateSelectorViewModel(wpAdminTaxSettingsURLProvider: wpAdminTaxSettingsURLProvider)

        XCTAssertNotNil(wpAdminTaxSettingsURL)
        XCTAssertEqual(viewModel.wpAdminTaxSettingsURL, wpAdminTaxSettingsURL)
    }
}
