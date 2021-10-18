import XCTest
@testable import WooCommerce

class ShippingLabelAddressTopBannerFactoryTests: XCTestCase {

    func test_top_banner_for_origin_address_has_no_actions() throws {
        // Given
        let topBannerView = ShippingLabelAddressTopBannerFactory.addressErrorTopBannerView(shipType: .origin,
                                                                                           hasContactInfo: false,
                                                                                           openMapPressed: {},
                                                                                           contactCustomerPressed: {})

        // Then
        XCTAssertNotNil(topBannerView)
        let view = try XCTUnwrap(topBannerView)
        let mirrorView = try TopBannerViewMirror(from: view)
        XCTAssertEqual(mirrorView.actionButtons.count, 0)
    }

    func test_top_banner_for_destination_address_without_contact_methods_has_one_action() throws {
        // Given
        let topBannerView = ShippingLabelAddressTopBannerFactory.addressErrorTopBannerView(shipType: .destination,
                                                                                           hasContactInfo: false,
                                                                                           openMapPressed: {},
                                                                                           contactCustomerPressed: {})

        // Then
        XCTAssertNotNil(topBannerView)
        let view = try XCTUnwrap(topBannerView)
        let mirrorView = try TopBannerViewMirror(from: view)
        XCTAssertEqual(mirrorView.actionButtons.count, 1)
    }

    func test_top_banner_for_destination_address_with_contact_info_has_two_actions() throws {
        // Given
        let topBannerView = ShippingLabelAddressTopBannerFactory.addressErrorTopBannerView(shipType: .destination,
                                                                                           hasContactInfo: true,
                                                                                           openMapPressed: {},
                                                                                           contactCustomerPressed: {})

        // Then
        XCTAssertNotNil(topBannerView)
        let view = try XCTUnwrap(topBannerView)
        let mirrorView = try TopBannerViewMirror(from: view)
        XCTAssertEqual(mirrorView.actionButtons.count, 2)
    }
}
