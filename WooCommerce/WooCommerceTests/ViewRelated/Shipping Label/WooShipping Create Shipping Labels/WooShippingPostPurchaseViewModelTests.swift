import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingPostPurchaseViewModelTests: XCTestCase {

    func test_inits_with_provided_properties() {
        // Given
        let labelSizes: [ShippingLabelPaperSize] = [.label, .letter, .a4]
        let trackingURL = URL(string: "https://woocommerce.com")
        let pickupURL = WooShippingCarrier.usps.pickupURL

        // When
        let viewModel = WooShippingPostPurchaseViewModel(labelSizes: labelSizes, trackingURL: trackingURL, pickupURL: pickupURL)

        // Then
        XCTAssertEqual(viewModel.labelSizes, labelSizes)
        XCTAssertEqual(viewModel.trackingURL, trackingURL)
        XCTAssertEqual(viewModel.pickupURL, pickupURL)
    }

    func test_labelSizes_includes_expected_default_values() {
        // Given
        let countrySetting = SiteSetting.fake().copy(settingID: "woocommerce_default_country",
                                                  value: "GB")
        let siteAddress = SiteAddress(siteSettings: [countrySetting])

        // When
        let viewModel = WooShippingPostPurchaseViewModel(shippingLabel: ShippingLabel.fake(), siteAddress: siteAddress)

        // Then
        assertEqual([.label, .letter], viewModel.labelSizes)
    }

    func test_labelSizes_includes_expected_values_for_country_with_a4_label_size() {
        // Given
        let countrySetting = SiteSetting.fake().copy(settingID: "woocommerce_default_country",
                                                  value: "US:NY")
        let siteAddress = SiteAddress(siteSettings: [countrySetting])

        // When
        let viewModel = WooShippingPostPurchaseViewModel(shippingLabel: ShippingLabel.fake(), siteAddress: siteAddress)

        // Then
        assertEqual([.label, .letter, .a4], viewModel.labelSizes)
    }

    func test_trackingURL_parsed_from_shipping_label() {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(carrierID: "usps", trackingNumber: "1234567890")

        // When
        let viewModel = WooShippingPostPurchaseViewModel(shippingLabel: shippingLabel)

        // Then
        let expectedTrackingURL = ShippingLabelTrackingURLGenerator.url(for: shippingLabel)
        XCTAssertEqual(viewModel.trackingURL, expectedTrackingURL)
    }

    func test_pickupUP_parsed_from_shipping_label() {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(carrierID: "usps")

        // When
        let viewModel = WooShippingPostPurchaseViewModel(shippingLabel: shippingLabel)

        // Then
        XCTAssertEqual(viewModel.pickupURL, WooShippingCarrier.usps.pickupURL)
    }

}
