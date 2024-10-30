import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingPostPurchaseViewModelTests: XCTestCase {

    func test_labelSizes_includes_expected_default_values() {
        // Given
        let countrySetting = SiteSetting.fake().copy(settingID: "woocommerce_default_country",
                                                  value: "GB")
        let siteAddress = SiteAddress(siteSettings: [countrySetting])

        // When
        let viewModel = WooShippingPostPurchaseViewModel(siteAddress: siteAddress)

        // Then
        assertEqual([.label, .letter], viewModel.labelSizes)
    }

    func test_labelSizes_includes_expected_values_for_country_with_a4_label_size() {
        // Given
        let countrySetting = SiteSetting.fake().copy(settingID: "woocommerce_default_country",
                                                  value: "US:NY")
        let siteAddress = SiteAddress(siteSettings: [countrySetting])

        // When
        let viewModel = WooShippingPostPurchaseViewModel(siteAddress: siteAddress)

        // Then
        assertEqual([.label, .letter, .a4], viewModel.labelSizes)
    }

}
