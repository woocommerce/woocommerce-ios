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

    func test_isDoneButtonEnabled_returns_the_expected_value() {
        // Given
        let viewModel = ShippingLabelCarriersViewModel(order: MockOrders().sampleOrder(),
                                                       originAddress: MockShippingLabelAddress.sampleAddress(),
                                                       destinationAddress: MockShippingLabelAddress.sampleAddress(),
                                                       packages: [],
                                                       selectedRate: MockShippingLabelCarrierRate.makeRate())

        // Then
        XCTAssertEqual(viewModel.isDoneButtonEnabled(), true)
    }

    func test_getSelectedRates_returns_the_expected_value() {
        // Given
        let viewModel = ShippingLabelCarriersViewModel(order: MockOrders().sampleOrder(),
                                                       originAddress: MockShippingLabelAddress.sampleAddress(),
                                                       destinationAddress: MockShippingLabelAddress.sampleAddress(),
                                                       packages: [],
                                                       selectedRate: MockShippingLabelCarrierRate.makeRate())

        // Then
        XCTAssertEqual(viewModel.getSelectedRates().selectedRate, MockShippingLabelCarrierRate.makeRate())
        XCTAssertEqual(viewModel.getSelectedRates().selectedSignatureRate, nil)
        XCTAssertEqual(viewModel.getSelectedRates().selectedAdultSignatureRate, nil)
    }

    func test_shouldDisplayTopBanner_returns_the_expected_value() {
        // Given
        let viewModel = ShippingLabelCarriersViewModel(order: MockOrders().sampleOrder().copy(shippingTotal: "10.00"),
                                                       originAddress: MockShippingLabelAddress.sampleAddress(),
                                                       destinationAddress: MockShippingLabelAddress.sampleAddress(),
                                                       packages: [],
                                                       selectedRate: MockShippingLabelCarrierRate.makeRate())

        // Then
        XCTAssertEqual(viewModel.shouldDisplayTopBanner, true)
    }

    func test_shippingMethod_returns_the_expected_value() {
        // Given
        let viewModel = ShippingLabelCarriersViewModel(order: MockOrders().sampleOrder().copy(shippingTotal: "10.00",
                                                                                              shippingLines: [ShippingLine(shippingID: 123,
                                                                                                                           methodTitle: "Flat rate",
                                                                                                                           methodID: "flat-rate",
                                                                                                                           total: "10.00",
                                                                                                                           totalTax: "0",
                                                                                                                           taxes: [])]),
                                                       originAddress: MockShippingLabelAddress.sampleAddress(),
                                                       destinationAddress: MockShippingLabelAddress.sampleAddress(),
                                                       packages: [],
                                                       selectedRate: MockShippingLabelCarrierRate.makeRate())

        // Then
        XCTAssertEqual(viewModel.shippingMethod, "Flat rate")
    }

    func test_shippingCost_returns_the_expected_value() {
        // Given
        let viewModel = ShippingLabelCarriersViewModel(order: MockOrders().sampleOrder().copy(shippingTotal: "10.00",
                                                                                              shippingLines: [ShippingLine(shippingID: 123,
                                                                                                                           methodTitle: "Flat rate",
                                                                                                                           methodID: "flat-rate",
                                                                                                                           total: "10.00",
                                                                                                                           totalTax: "0",
                                                                                                                           taxes: [])]),
                                                       originAddress: MockShippingLabelAddress.sampleAddress(),
                                                       destinationAddress: MockShippingLabelAddress.sampleAddress(),
                                                       packages: [],
                                                       selectedRate: MockShippingLabelCarrierRate.makeRate())

        // Then
        XCTAssertEqual(viewModel.shippingCost, "$10.00")
    }
}

private extension ShippingLabelCarriersViewModelTests {
    func sampleShippingLabelCarriersAndRates() -> ShippingLabelCarriersAndRates {
        return ShippingLabelCarriersAndRates(defaultRates: [MockShippingLabelCarrierRate.makeRate(), MockShippingLabelCarrierRate.makeRate(title: "UPS")],
                                             signatureRequired: [MockShippingLabelCarrierRate.makeRate(title: "USPS - Parcel Select Mail",
                                                                                                       rate: 45.060000000000002)],
                                             adultSignatureRequired: [MockShippingLabelCarrierRate.makeRate(title: "USPS - Parcel Select Mail",
                                                                                                            rate: 50.060000000000002)])
    }
}
