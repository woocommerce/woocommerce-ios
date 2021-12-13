import XCTest
@testable import WooCommerce
import Yosemite

final class ShippingLabelCarriersViewModelTests: XCTestCase {

    func test_sections_generation_returns_expected_data() throws {
        // Given
        let viewModel = ShippingLabelCarriersViewModel(order: MockOrders().sampleOrder(),
                                                       originAddress: MockShippingLabelAddress.sampleAddress(),
                                                       destinationAddress: MockShippingLabelAddress.sampleAddress(),
                                                       packages: [],
                                                       currencySettings: CurrencySettings())
        XCTAssertEqual(viewModel.sections.count, 0)

        // When
        viewModel.generateSections(response: sampleShippingLabelCarriersAndRates())

        // Then
        XCTAssertEqual(viewModel.sections.count, 1)
        XCTAssertEqual(viewModel.sections.first?.rows.count, 3)

        let row = try XCTUnwrap(viewModel.sections.first?.rows.first)
        XCTAssertEqual(row.selected, false)
        XCTAssertEqual(row.signatureSelected, false)
        XCTAssertEqual(row.adultSignatureSelected, false)
        XCTAssertEqual(row.title, "USPS - Parcel Select Mail")
        XCTAssertEqual(row.subtitle, "2 business days")
        XCTAssertEqual(row.price, "$40.06")
        XCTAssertEqual(row.carrierLogo, UIImage(named: "shipping-label-usps-logo"))
        XCTAssertEqual(row.extraInfo, "Includes USPS tracking, Eligible for free pickup")
        XCTAssertEqual(row.displaySignatureRequired, true)
        XCTAssertEqual(row.displayAdultSignatureRequired, true)
        XCTAssertEqual(row.signatureRequiredText, "Signature required (+$5.00)")
        XCTAssertEqual(row.adultSignatureRequiredText, "Adult signature required (+$10.00)")

        let row2 = try XCTUnwrap(viewModel.sections.first?.rows[1])
        XCTAssertEqual(row2.selected, false)
        XCTAssertEqual(row2.signatureSelected, false)
        XCTAssertEqual(row2.adultSignatureSelected, false)
        XCTAssertEqual(row2.title, "UPS")
        XCTAssertEqual(row2.subtitle, "2 business days")
        XCTAssertEqual(row2.price, "$40.06")
        XCTAssertEqual(row2.carrierLogo, UIImage(named: "shipping-label-usps-logo"))
        XCTAssertEqual(row2.extraInfo, "Includes USPS tracking, Insurance (up to $2,500.00), Eligible for free pickup")
        XCTAssertEqual(row2.displaySignatureRequired, false)
        XCTAssertEqual(row2.displayAdultSignatureRequired, false)
        XCTAssertEqual(row2.signatureRequiredText, "")
        XCTAssertEqual(row2.adultSignatureRequiredText, "")

        let row3 = try XCTUnwrap(viewModel.sections.first?.rows[2])
        XCTAssertEqual(row3.selected, false)
        XCTAssertEqual(row3.signatureSelected, false)
        XCTAssertEqual(row3.adultSignatureSelected, false)
        XCTAssertEqual(row3.title, "UPS")
        XCTAssertEqual(row3.subtitle, "2 business days")
        XCTAssertEqual(row3.price, "$40.06")
        XCTAssertEqual(row3.carrierLogo, UIImage(named: "shipping-label-usps-logo"))
        XCTAssertEqual(row3.extraInfo, "Includes USPS tracking, Insurance (limited), Eligible for free pickup")
        XCTAssertEqual(row3.displaySignatureRequired, false)
        XCTAssertEqual(row3.displayAdultSignatureRequired, false)
        XCTAssertEqual(row3.signatureRequiredText, "")
        XCTAssertEqual(row3.adultSignatureRequiredText, "")
    }

    func test_isDoneButtonEnabled_returns_the_expected_value() {
        // Given
        let viewModel = ShippingLabelCarriersViewModel(order: MockOrders().sampleOrder(),
                                                       originAddress: MockShippingLabelAddress.sampleAddress(),
                                                       destinationAddress: MockShippingLabelAddress.sampleAddress(),
                                                       packages: [ShippingLabelPackageSelected.fake()],
                                                       selectedRates: sampleShippingLabelSelectedRate(),
                                                       currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.isDoneButtonEnabled(), true)
    }

    func test_getSelectedRates_returns_the_expected_value() {
        // Given
        let viewModel = ShippingLabelCarriersViewModel(order: MockOrders().sampleOrder(),
                                                       originAddress: MockShippingLabelAddress.sampleAddress(),
                                                       destinationAddress: MockShippingLabelAddress.sampleAddress(),
                                                       packages: [],
                                                       selectedRates: sampleShippingLabelSelectedRate(),
                                                       currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.getSelectedRates().first?.rate, MockShippingLabelCarrierRate.makeRate())
        XCTAssertEqual(viewModel.getSelectedRates().first?.signatureRate, MockShippingLabelCarrierRate.makeRate(title: "USPS - Parcel Select Mail",
                                                                                                                rate: 45.060000000000002))
        XCTAssertEqual(viewModel.getSelectedRates().first?.adultSignatureRate, MockShippingLabelCarrierRate.makeRate(title: "USPS - Parcel Select Mail",
                                                                                                                     rate: 50.060000000000002))
    }

    func test_shouldDisplayTopBanner_returns_the_expected_value() {
        // Given
        let viewModel = ShippingLabelCarriersViewModel(order: MockOrders().sampleOrder().copy(shippingTotal: "10.00"),
                                                       originAddress: MockShippingLabelAddress.sampleAddress(),
                                                       destinationAddress: MockShippingLabelAddress.sampleAddress(),
                                                       packages: [],
                                                       selectedRates: sampleShippingLabelSelectedRate(),
                                                       currencySettings: CurrencySettings())

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
                                                       selectedRates: sampleShippingLabelSelectedRate(),
                                                       currencySettings: CurrencySettings())

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
                                                       selectedRates: sampleShippingLabelSelectedRate(),
                                                       currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.shippingCost, "$10.00")
    }
}

private extension ShippingLabelCarriersViewModelTests {
    func sampleShippingLabelSelectedRate() -> [ShippingLabelSelectedRate] {
        return [ShippingLabelSelectedRate(packageID: "123",
                                          rate: MockShippingLabelCarrierRate.makeRate(),
                                          signatureRate: MockShippingLabelCarrierRate.makeRate(title: "USPS - Parcel Select Mail",
                                                                                               rate: 45.060000000000002),
                                          adultSignatureRate: MockShippingLabelCarrierRate.makeRate(title: "USPS - Parcel Select Mail",
                                                                                                    rate: 50.060000000000002))]
    }

    func sampleShippingLabelCarriersAndRates() -> [ShippingLabelCarriersAndRates] {
        return [ShippingLabelCarriersAndRates(packageID: "123",
                                              defaultRates: [
                                                MockShippingLabelCarrierRate.makeRate(),
                                                MockShippingLabelCarrierRate.makeRate(title: "UPS", insurance: "2500"),
                                                MockShippingLabelCarrierRate.makeRate(title: "UPS", insurance: "limited")],
                                             signatureRequired: [MockShippingLabelCarrierRate.makeRate(title: "USPS - Parcel Select Mail",
                                                                                                       rate: 45.060000000000002)],
                                             adultSignatureRequired:
                                                [MockShippingLabelCarrierRate.makeRate(title: "USPS - Parcel Select Mail",
                                                                                                            rate: 50.060000000000002)])]
    }
}
