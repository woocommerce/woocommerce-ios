import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingServiceViewModelTests: XCTestCase {

    func test_init_sets_expected_values() {
        // Given
        let viewModel = WooShippingServiceViewModel()

        // Then
        XCTAssertNil(viewModel.selectedRate)
        XCTAssertTrue(viewModel.isLoadingRates)
    }

    func test_generateServiceTabs_returns_expected_data() throws {
        // Given
        let viewModel = WooShippingServiceViewModel(standardRates: sampleStandardRates(),
                                                    signatureRates: sampleSignatureRates(),
                                                    adultSignatureRates: sampleAdultSignatureRates())

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

    func test_selecting_service_card_standard_rate_updates_expected_values() {
        // Given
        let viewModel = WooShippingServiceViewModel(standardRates: sampleStandardRates())
        let card = viewModel.serviceTabs[0].cards[1]
        XCTAssertNil(viewModel.selectedRate)
        XCTAssertFalse(card.selected)

        // When
        card.selectRate()

        // Then
        XCTAssertNotNil(viewModel.selectedRate)
        XCTAssertNil(viewModel.selectedRate?.signatureRate)
        XCTAssertNil(viewModel.selectedRate?.adultSignatureRate)
        XCTAssertEqual(viewModel.selectedRate?.rate.title, card.title)
        XCTAssertEqual(viewModel.serviceTabs[0].cards[1].selected, true)
    }

    func test_selecting_service_card_signature_rate_updates_expected_values() {
        // Given
        let viewModel = WooShippingServiceViewModel(standardRates: sampleStandardRates(),
                                                    signatureRates: sampleSignatureRates())
        let card = viewModel.serviceTabs[0].cards[1]
        XCTAssertNil(viewModel.selectedRate)
        XCTAssertFalse(card.selected)

        // When
        card.signatureRequirement = .signatureRequired
        card.selectRate()

        // Then
        XCTAssertNotNil(viewModel.selectedRate)
        XCTAssertNotNil(viewModel.selectedRate?.signatureRate)
        XCTAssertNil(viewModel.selectedRate?.adultSignatureRate)
        XCTAssertEqual(viewModel.serviceTabs[0].cards[1].selected, true)
    }

    func test_selecting_service_card_adult_signature_rate_updates_expected_values() {
        // Given
        let viewModel = WooShippingServiceViewModel(standardRates: sampleStandardRates(),
                                                    adultSignatureRates: sampleAdultSignatureRates())
        let card = viewModel.serviceTabs[0].cards[1]
        XCTAssertNil(viewModel.selectedRate)
        XCTAssertFalse(card.selected)

        // When
        card.signatureRequirement = .adultSignatureRequired
        card.selectRate()

        // Then
        XCTAssertNotNil(viewModel.selectedRate)
        XCTAssertNil(viewModel.selectedRate?.signatureRate)
        XCTAssertNotNil(viewModel.selectedRate?.adultSignatureRate)
        XCTAssertEqual(viewModel.serviceTabs[0].cards[1].selected, true)
    }

    func test_sortShipping_by_price_returns_sorted_list() {
        // Given
        let viewModel = WooShippingServiceViewModel(standardRates: sampleStandardRates())

        // When
        viewModel.sortShipping(by: .price)

        // Then
        let uspsCards = viewModel.serviceTabs.first?.cards
        XCTAssertEqual(uspsCards?.count, 2)
        XCTAssertEqual(uspsCards?.first?.title, "USPS - Media Mail")
    }

    func test_shortShipping_by_deliveryDays_returns_sorted_list() {
        // Given
        let viewModel = WooShippingServiceViewModel(standardRates: sampleStandardRates())

        // When
        viewModel.sortShipping(by: .deliveryTime)

        // Then
        let uspsCards = viewModel.serviceTabs.first?.cards
        XCTAssertEqual(uspsCards?.count, 2)
        XCTAssertEqual(uspsCards?.first?.title, "USPS - Parcel Select Mail")
    }

}

private extension WooShippingServiceViewModelTests {
    func sampleStandardRates() -> [ShippingLabelCarrierRate] {
        [ShippingLabelCarrierRate(title: "USPS - Media Mail",
                                  insurance: "100",
                                  retailRate: 8,
                                  rate: 7.53,
                                  rateID: "rate_a8a29d5f34984722942f466c30ea27ef",
                                  serviceID: "",
                                  carrierID: "usps",
                                  shipmentID: "",
                                  hasTracking: true,
                                  isSelected: false,
                                  isPickupFree: true,
                                  deliveryDays: 7,
                                  deliveryDateGuaranteed: false),
         ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                  insurance: "100",
                                  retailRate: 40.06,
                                  rate: 40.06,
                                  rateID: "rate_a8a29d5f34984722942f466c30ea27eh",
                                  serviceID: "",
                                  carrierID: "usps",
                                  shipmentID: "",
                                  hasTracking: true,
                                  isSelected: false,
                                  isPickupFree: true,
                                  deliveryDays: 2,
                                  deliveryDateGuaranteed: false),
         ShippingLabelCarrierRate(title: "DHL - Next Day",
                                  insurance: "100",
                                  retailRate: 15,
                                  rate: 14.22,
                                  rateID: "rate_a8a29d5f34984722942f466c30ea27eg",
                                  serviceID: "",
                                  carrierID: "dhlexpress",
                                  shipmentID: "",
                                  hasTracking: true,
                                  isSelected: false,
                                  isPickupFree: true,
                                  deliveryDays: 1,
                                  deliveryDateGuaranteed: false)]
    }

    func sampleSignatureRates() -> [ShippingLabelCarrierRate] {
        [ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                  insurance: "100",
                                  retailRate: 42.76,
                                  rate: 42.76,
                                  rateID: "rate_a8a29d5f34984722942f466c30ea27ei",
                                  serviceID: "",
                                  carrierID: "usps",
                                  shipmentID: "",
                                  hasTracking: true,
                                  isSelected: false,
                                  isPickupFree: true,
                                  deliveryDays: 2,
                                  deliveryDateGuaranteed: false)]
    }

    func sampleAdultSignatureRates() -> [ShippingLabelCarrierRate] {
        [ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                  insurance: "100",
                                  retailRate: 46.96,
                                  rate: 46.96,
                                  rateID: "rate_a8a29d5f34984722942f466c30ea27ej",
                                  serviceID: "",
                                  carrierID: "usps",
                                  shipmentID: "",
                                  hasTracking: true,
                                  isSelected: false,
                                  isPickupFree: true,
                                  deliveryDays: 2,
                                  deliveryDateGuaranteed: false)]
    }
}
