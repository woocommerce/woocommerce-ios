import XCTest
@testable import WooCommerce
import Yosemite
import WooFoundation

final class WooShippingServiceCardViewModelTests: XCTestCase {

    func test_it_inits_with_expected_values() {
        // Given
        let viewModel = WooShippingServiceCardViewModel(selected: true,
                                                        signatureRequired: true,
                                                        rate: MockShippingLabelCarrierRate.makeRate(rate: 40.33, insurance: "100"),
                                                        signatureRate: MockShippingLabelCarrierRate.makeRate(rate: 45.99),
                                                        adultSignatureRate: MockShippingLabelCarrierRate.makeRate(rate: 51.33),
                                                        currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.selected, true)
        XCTAssertEqual(viewModel.signatureRequirement, .signatureRequired)
        XCTAssertEqual(viewModel.title, "USPS - Parcel Select Mail")
        XCTAssertEqual(viewModel.daysToDeliveryLabel, "2 business days")
        XCTAssertEqual(viewModel.rateLabel, "$40.33")
        XCTAssertEqual(viewModel.carrierLogo, UIImage(named: "shipping-label-usps-logo"))
        XCTAssertEqual(viewModel.trackingLabel, "Tracking")
        XCTAssertEqual(viewModel.insuranceLabel, "Insurance (up to $100.00)")
        XCTAssertEqual(viewModel.freePickupLabel, "Free pickup")
        XCTAssertEqual(viewModel.extraInfoLabel, "Includes tracking, insurance (up to $100.00), free pickup")
        XCTAssertEqual(viewModel.signatureRequiredLabel, "Signature Required (+$5.66)")
        XCTAssertEqual(viewModel.adultSignatureRequiredLabel, "Adult Signature Required (+$11.00)")
    }

    func test_it_inits_with_expected_values_with_no_extras() {
        // Given
        let viewModel = WooShippingServiceCardViewModel(rate: MockShippingLabelCarrierRate.makeRate(rate: 40.33, hasTracking: false, isPickupFree: false),
                                                        currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.selected, false)
        XCTAssertEqual(viewModel.signatureRequirement, .none)
        XCTAssertEqual(viewModel.title, "USPS - Parcel Select Mail")
        XCTAssertEqual(viewModel.daysToDeliveryLabel, "2 business days")
        XCTAssertEqual(viewModel.rateLabel, "$40.33")
        XCTAssertEqual(viewModel.carrierLogo, UIImage(named: "shipping-label-usps-logo"))
        XCTAssertNil(viewModel.trackingLabel)
        XCTAssertNil(viewModel.insuranceLabel)
        XCTAssertNil(viewModel.freePickupLabel)
        XCTAssertNil(viewModel.extraInfoLabel)
        XCTAssertNil(viewModel.signatureRequiredLabel)
        XCTAssertNil(viewModel.adultSignatureRequiredLabel)
    }

    func test_it_inits_with_expected_values_with_extra_services() {
        // Given
        let viewModel = WooShippingServiceCardViewModel(selected: true,
                                                        signatureRequired: true,
                                                        carbonNeutralSelected: true,
                                                        saturdayDeliverySelected: false,
                                                        additionalHandlingSelected: true,
                                                        rate: MockShippingLabelCarrierRate.makeRate(rate: 40.33, insurance: "100"),
                                                        signatureRate: MockShippingLabelCarrierRate.makeRate(rate: 45.99),
                                                        adultSignatureRate: MockShippingLabelCarrierRate.makeRate(rate: 51.33),
                                                        carbonNeutralRate: MockShippingLabelCarrierRate.makeRate(rate: 56.03),
                                                        saturdayDeliveryRate: MockShippingLabelCarrierRate.makeRate(rate: 67.12),
                                                        additionalHandlingRate: MockShippingLabelCarrierRate.makeRate(rate: 44.22),
                                                        currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.selected, true)
        XCTAssertEqual(viewModel.signatureRequirement, .signatureRequired)
        XCTAssertEqual(viewModel.title, "USPS - Parcel Select Mail")
        XCTAssertEqual(viewModel.daysToDeliveryLabel, "2 business days")
        XCTAssertEqual(viewModel.rateLabel, "$40.33")
        XCTAssertEqual(viewModel.carrierLogo, UIImage(named: "shipping-label-usps-logo"))
        XCTAssertEqual(viewModel.trackingLabel, "Tracking")
        XCTAssertEqual(viewModel.insuranceLabel, "Insurance (up to $100.00)")
        XCTAssertEqual(viewModel.freePickupLabel, "Free pickup")
        XCTAssertEqual(viewModel.extraInfoLabel, "Includes tracking, insurance (up to $100.00), free pickup")
        XCTAssertEqual(viewModel.signatureRequiredLabel, "Signature Required (+$5.66)")
        XCTAssertEqual(viewModel.adultSignatureRequiredLabel, "Adult Signature Required (+$11.00)")
        XCTAssertEqual(viewModel.carbonNeutralLabel, "Carbon Neutral (+$15.70)")
        XCTAssertEqual(viewModel.saturdayDeliveryLabel, "Saturday Delivery (+$26.79)")
        XCTAssertEqual(viewModel.additionalHandlingLabel, "Additional Handling (+$3.89)")
    }

    func test_it_inits_with_expected_values_with_extra_services_negative_surcharge() {
        // Given
        let viewModel = WooShippingServiceCardViewModel(selected: true,
                                                        signatureRequired: true,
                                                        carbonNeutralSelected: true,
                                                        saturdayDeliverySelected: false,
                                                        additionalHandlingSelected: true,
                                                        rate: MockShippingLabelCarrierRate.makeRate(rate: 25.95, insurance: "100"),
                                                        signatureRate: MockShippingLabelCarrierRate.makeRate(rate: 25.69),
                                                        adultSignatureRate: MockShippingLabelCarrierRate.makeRate(rate: 33.05),
                                                        carbonNeutralRate: MockShippingLabelCarrierRate.makeRate(rate: 26.15),
                                                        saturdayDeliveryRate: MockShippingLabelCarrierRate.makeRate(rate: 25.69),
                                                        additionalHandlingRate: MockShippingLabelCarrierRate.makeRate(rate: 38.9),
                                                        currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.selected, true)
        XCTAssertEqual(viewModel.signatureRequirement, .signatureRequired)
        XCTAssertEqual(viewModel.title, "USPS - Parcel Select Mail")
        XCTAssertEqual(viewModel.daysToDeliveryLabel, "2 business days")
        XCTAssertEqual(viewModel.rateLabel, "$25.95")
        XCTAssertEqual(viewModel.carrierLogo, UIImage(named: "shipping-label-usps-logo"))
        XCTAssertEqual(viewModel.trackingLabel, "Tracking")
        XCTAssertEqual(viewModel.insuranceLabel, "Insurance (up to $100.00)")
        XCTAssertEqual(viewModel.freePickupLabel, "Free pickup")
        XCTAssertEqual(viewModel.extraInfoLabel, "Includes tracking, insurance (up to $100.00), free pickup")
        XCTAssertEqual(viewModel.signatureRequiredLabel, "Signature Required (-$0.26)")
        XCTAssertEqual(viewModel.adultSignatureRequiredLabel, "Adult Signature Required (+$7.10)")
        XCTAssertEqual(viewModel.carbonNeutralLabel, "Carbon Neutral (+$0.20)")
        XCTAssertEqual(viewModel.saturdayDeliveryLabel, "Saturday Delivery (-$0.26)")
        XCTAssertEqual(viewModel.additionalHandlingLabel, "Additional Handling (+$12.95)")
    }

    func test_insuranceLabel_shows_expected_value_for_non_number_insurance() {
        // Given
        let viewModel = WooShippingServiceCardViewModel(rate: MockShippingLabelCarrierRate.makeRate(insurance: "limited"))

        // Then
        XCTAssertEqual(viewModel.insuranceLabel, "Insurance (limited)")
    }

    func test_handleTap_enables_newly_selected_rate() {
        // Given
        let newSelection: WooShippingServiceCardViewModel.SignatureRequirement = .signatureRequired
        let viewModel = WooShippingServiceCardViewModel(rate: MockShippingLabelCarrierRate.makeRate(rate: 40.33, insurance: "100"),
                                                        signatureRate: MockShippingLabelCarrierRate.makeRate(rate: 45.99),
                                                        adultSignatureRate: MockShippingLabelCarrierRate.makeRate(rate: 51.33))

        // When
        viewModel.handleTap(on: newSelection)

        // Then
        XCTAssertEqual(viewModel.signatureRequirement, newSelection)
    }

    func test_handleTap_disables_previously_selected_rate() {
        // Given
        let viewModel = WooShippingServiceCardViewModel(adultSignatureRequired: true,
                                                        rate: MockShippingLabelCarrierRate.makeRate(rate: 40.33, insurance: "100"),
                                                        signatureRate: MockShippingLabelCarrierRate.makeRate(rate: 45.99),
                                                        adultSignatureRate: MockShippingLabelCarrierRate.makeRate(rate: 51.33))

        // When
        viewModel.handleTap(on: .adultSignatureRequired)

        // Then
        XCTAssertEqual(viewModel.signatureRequirement, .none)
    }

    func test_handleTap_toggles_extra_rates() {
        // Given
        let viewModel = WooShippingServiceCardViewModel(adultSignatureRequired: true,
                                                        rate: MockShippingLabelCarrierRate.makeRate(rate: 40.33, insurance: "100"),
                                                        signatureRate: MockShippingLabelCarrierRate.makeRate(rate: 45.99),
                                                        adultSignatureRate: MockShippingLabelCarrierRate.makeRate(rate: 51.33),
                                                        carbonNeutralRate: MockShippingLabelCarrierRate.makeRate(rate: 45.99),
                                                        saturdayDeliveryRate: MockShippingLabelCarrierRate.makeRate(rate: 22.4),
                                                        additionalHandlingRate: MockShippingLabelCarrierRate.makeRate(rate: 20.53))
        XCTAssertFalse(viewModel.carbonNeutralSelected)
        XCTAssertFalse(viewModel.saturdayDeliverySelected)
        XCTAssertFalse(viewModel.additionalHandlingSelected)

        // When
        viewModel.handleTap(on: .carbonNeutral)

        // Then
        XCTAssertTrue(viewModel.carbonNeutralSelected)

        // When
        viewModel.handleTap(on: .saturdayDelivery)

        // Then
        XCTAssertTrue(viewModel.saturdayDeliverySelected)

        // When
        viewModel.handleTap(on: .additionalHandling)

        // Then
        XCTAssertTrue(viewModel.additionalHandlingSelected)
    }

    func test_selectRate_calls_completion_block_with_rate_title_and_signature_requirement_and_extra_services() {
        // Given
        let rate = MockShippingLabelCarrierRate.makeRate(rate: 40.33, insurance: "100")
        var completionRateTitle: String? = nil
        var completionSignatureRequirement: WooShippingServiceCardViewModel.SignatureRequirement? = nil
        var completionSaturdayDelivery = false
        var completionCarbonNeutral = false
        var completionAdditionalHandling = false
        let viewModel = WooShippingServiceCardViewModel(
            adultSignatureRequired: true,
            rate: rate,
            signatureRate: MockShippingLabelCarrierRate.makeRate(rate: 45.99),
            adultSignatureRate: MockShippingLabelCarrierRate.makeRate(rate: 51.33),
        ) { title, signature, carbonNeutral, saturdayDelivery, additionalHandling in
            completionRateTitle = title
            completionSignatureRequirement = signature
            completionCarbonNeutral = carbonNeutral
            completionSaturdayDelivery = saturdayDelivery
            completionAdditionalHandling = additionalHandling
        }

        // When
        viewModel.selectRate()

        // Then
        XCTAssertEqual(completionRateTitle, rate.title)
        XCTAssertEqual(completionSignatureRequirement, .adultSignatureRequired)
        XCTAssertFalse(completionCarbonNeutral)
        XCTAssertFalse(completionSaturdayDelivery)
        XCTAssertFalse(completionAdditionalHandling)
    }

}
