import XCTest
@testable import WooCommerce
import Yosemite

final class ShippingLabelCarriersViewModelTests: XCTestCase {

    func test_rows_generation_returns_expected_data() {
        // Given
        let viewModel = ShippingLabelCarriersViewModel(order: MockOrders().sampleOrder(),
                                                       originAddress: MockShippingLabelAddress.sampleAddress(),
                                                       destinationAddress: MockShippingLabelAddress.sampleAddress(),
                                                       packages: [])
        XCTAssertEqual(viewModel.rows.count, 0)

        // When
        viewModel.generateRows(response: sampleShippingLabelCarriersAndRates())

        // Then
        let row = viewModel.rows.first
        XCTAssertEqual(row?.selected, false)
        XCTAssertEqual(row?.signatureSelected, false)
        XCTAssertEqual(row?.adultSignatureSelected, false)
        XCTAssertEqual(row?.title, "USPS - Parcel Select Mail")
        XCTAssertEqual(row?.subtitle, "2 business days")
        XCTAssertEqual(row?.price, "$40.06")
        XCTAssertEqual(row?.carrierLogo, UIImage(named: "shipping-label-usps-logo"))
        XCTAssertEqual(row?.extraInfo, "Includes USPS tracking, Eligible for free pickup")
        XCTAssertEqual(row?.displaySignatureRequired, true)
        XCTAssertEqual(row?.displayAdultSignatureRequired, true)
        XCTAssertEqual(row?.signatureRequiredText, "Signature required (+$5.00)")
        XCTAssertEqual(row?.adultSignatureRequiredText, "Adult signature required (+$10.00)")

        let row2 = viewModel.rows.last
        XCTAssertEqual(row2?.selected, false)
        XCTAssertEqual(row2?.signatureSelected, false)
        XCTAssertEqual(row2?.adultSignatureSelected, false)
        XCTAssertEqual(row2?.title, "UPS")
        XCTAssertEqual(row2?.subtitle, "2 business days")
        XCTAssertEqual(row2?.price, "$40.06")
        XCTAssertEqual(row2?.carrierLogo, UIImage(named: "shipping-label-usps-logo"))
        XCTAssertEqual(row2?.extraInfo, "Includes USPS tracking, Eligible for free pickup")
        XCTAssertEqual(row2?.displaySignatureRequired, false)
        XCTAssertEqual(row2?.displayAdultSignatureRequired, false)
        XCTAssertEqual(row2?.signatureRequiredText, "")
        XCTAssertEqual(row2?.adultSignatureRequiredText, "")
    }
}

private extension ShippingLabelCarriersViewModelTests {
    func sampleShippingLabelCarriersAndRates() -> ShippingLabelCarriersAndRates {
        return ShippingLabelCarriersAndRates(defaultRates: [sampleCarrierRate(), sampleCarrierRate(title: "UPS")],
                                             signatureRequired: [sampleSignatureRate()],
                                             adultSignatureRequired: [sampleAdultSignatureRate()])
    }

    func sampleCarrierRate(title: String = "USPS - Parcel Select Mail") -> ShippingLabelCarrierRate {
        let rate = ShippingLabelCarrierRate(title: title,
                                            insurance: 0,
                                            retailRate: 40.060000000000002,
                                            rate: 40.060000000000002,
                                            rateID: "rate_a8a29d5f34984722942f466c30ea27ef",
                                            serviceID: "ParcelSelect",
                                            carrierID: "usps",
                                            shipmentID: "shp_e0e3c2f4606c4b198d0cbd6294baed56",
                                            hasTracking: true,
                                            isSelected: false,
                                            isPickupFree: true,
                                            deliveryDays: 2,
                                            deliveryDateGuaranteed: false)

        return rate
    }

    func sampleSignatureRate() -> ShippingLabelCarrierRate {
        let rate = ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                            insurance: 0,
                                            retailRate: 45.060000000000002,
                                            rate: 45.060000000000002,
                                            rateID: "rate_a8a29d5f34984722942f466c30ea27ef",
                                            serviceID: "ParcelSelect",
                                            carrierID: "usps",
                                            shipmentID: "shp_e0e3c2f4606c4b198d0cbd6294baed56",
                                            hasTracking: true,
                                            isSelected: false,
                                            isPickupFree: true,
                                            deliveryDays: 2,
                                            deliveryDateGuaranteed: false)

        return rate
    }

    func sampleAdultSignatureRate() -> ShippingLabelCarrierRate {
        let rate = ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                            insurance: 0,
                                            retailRate: 50.060000000000002,
                                            rate: 50.060000000000002,
                                            rateID: "rate_a8a29d5f34984722942f466c30ea27ef",
                                            serviceID: "ParcelSelect",
                                            carrierID: "usps",
                                            shipmentID: "shp_e0e3c2f4606c4b198d0cbd6294baed56",
                                            hasTracking: true,
                                            isSelected: false,
                                            isPickupFree: true,
                                            deliveryDays: 2,
                                            deliveryDateGuaranteed: false)

        return rate
    }
}
