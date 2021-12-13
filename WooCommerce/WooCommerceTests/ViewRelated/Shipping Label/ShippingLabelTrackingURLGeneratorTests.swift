import XCTest
@testable import WooCommerce

final class ShippingLabelTrackingURLGeneratorTests: XCTestCase {
    func test_url_is_nil_with_unsupported_carrier() {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(carrierID: "panda_express")

        // When
        let url = ShippingLabelTrackingURLGenerator.url(for: shippingLabel)

        // Then
        XCTAssertNil(url)
    }

    func test_url_is_nil_with_empty_tracking_number() {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(carrierID: "dhl", trackingNumber: "")

        // When
        let url = ShippingLabelTrackingURLGenerator.url(for: shippingLabel)

        // Then
        XCTAssertNil(url)
    }

    func test_url_contains_tracking_number_for_supported_carriers() {
        // Given
        let supportedCarriers = ["usps", "fedex", "ups", "dhl", "dhlexpress"]
        let trackingNumber = "166"

        // When
        let urls = supportedCarriers.compactMap {
            ShippingLabelTrackingURLGenerator.url(for: MockShippingLabel.emptyLabel().copy(carrierID: $0, trackingNumber: trackingNumber))
        }

        // Then
        XCTAssertEqual(urls.count, supportedCarriers.count)
        urls.forEach { XCTAssertTrue($0.absoluteString.contains(trackingNumber) == true) }
    }
}
