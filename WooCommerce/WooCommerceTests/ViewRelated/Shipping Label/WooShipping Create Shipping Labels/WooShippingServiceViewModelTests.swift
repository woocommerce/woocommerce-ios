import XCTest
@testable import WooCommerce

final class WooShippingServiceViewModelTests: XCTestCase {

    func test_generateServiceTabs_returns_expected_data() throws {
        // Given
        let viewModel = WooShippingServiceViewModel()

        // Then
        XCTAssertEqual(viewModel.serviceTabs.count, 2)
        XCTAssertEqual(viewModel.serviceTabs[0].cards.count, 2)
        XCTAssertEqual(viewModel.serviceTabs[1].cards.count, 1)

        let rate = try XCTUnwrap(viewModel.serviceTabs[0].cards[0])
        XCTAssertEqual(rate.selected, false)
        XCTAssertEqual(rate.signatureRequirement, .none)
        XCTAssertEqual(rate.title, "USPS - Media Mail")
        XCTAssertEqual(rate.daysToDeliveryLabel, "7 business days")
        XCTAssertEqual(rate.rateLabel, "$7.53")
        XCTAssertEqual(rate.carrierLogo, WooShippingCarrier.usps.logo)
        XCTAssertEqual(rate.trackingLabel, "Tracking")
        XCTAssertEqual(rate.insuranceLabel, "Insurance (up to $100.00)")
        XCTAssertEqual(rate.freePickupLabel, "Free pickup")
        XCTAssertEqual(rate.extraInfoLabel, "Includes tracking, insurance (up to $100.00), free pickup")
        XCTAssertNil(rate.signatureRequiredLabel)
        XCTAssertNil(rate.adultSignatureRequiredLabel)

        let rate2 = try XCTUnwrap(viewModel.serviceTabs[0].cards[1])
        XCTAssertEqual(rate2.selected, false)
        XCTAssertEqual(rate2.signatureRequirement, .none)
        XCTAssertEqual(rate2.title, "USPS - Parcel Select Mail")
        XCTAssertEqual(rate2.daysToDeliveryLabel, "2 business days")
        XCTAssertEqual(rate2.rateLabel, "$40.06")
        XCTAssertEqual(rate2.carrierLogo, WooShippingCarrier.usps.logo)
        XCTAssertEqual(rate2.trackingLabel, "Tracking")
        XCTAssertEqual(rate2.insuranceLabel, "Insurance (up to $100.00)")
        XCTAssertEqual(rate2.freePickupLabel, "Free pickup")
        XCTAssertEqual(rate2.extraInfoLabel, "Includes tracking, insurance (up to $100.00), free pickup")
        XCTAssertEqual(rate2.signatureRequiredLabel, "Signature Required (+$2.70)")
        XCTAssertEqual(rate2.adultSignatureRequiredLabel, "Adult Signature Required (+$6.90)")

        let rate3 = try XCTUnwrap(viewModel.serviceTabs[1].cards[0])
        XCTAssertEqual(rate3.selected, false)
        XCTAssertEqual(rate3.signatureRequirement, .none)
        XCTAssertEqual(rate3.title, "DHL - Next Day")
        XCTAssertEqual(rate3.daysToDeliveryLabel, "1 business day")
        XCTAssertEqual(rate3.rateLabel, "$14.22")
        XCTAssertEqual(rate3.carrierLogo, WooShippingCarrier.dhlExpress.logo)
        XCTAssertEqual(rate3.trackingLabel, "Tracking")
        XCTAssertEqual(rate3.insuranceLabel, "Insurance (up to $100.00)")
        XCTAssertEqual(rate3.freePickupLabel, "Free pickup")
        XCTAssertEqual(rate3.extraInfoLabel, "Includes tracking, insurance (up to $100.00), free pickup")
        XCTAssertNil(rate3.signatureRequiredLabel)
        XCTAssertNil(rate3.adultSignatureRequiredLabel)
    }

}
