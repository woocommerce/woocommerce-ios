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
        XCTAssertEqual(viewModel.rateLabel, "$45.99")
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

    func test_selectRate_calls_completion_block_with_rate_title_and_signature_requirement() {
        // Given
        let rate = MockShippingLabelCarrierRate.makeRate(rate: 40.33, insurance: "100")
        var completionRateTitle: String? = nil
        var completionSignatureRequirement: WooShippingServiceCardViewModel.SignatureRequirement? = nil
        let viewModel = WooShippingServiceCardViewModel(adultSignatureRequired: true,
                                                        rate: rate,
                                                        signatureRate: MockShippingLabelCarrierRate.makeRate(rate: 45.99),
                                                        adultSignatureRate: MockShippingLabelCarrierRate.makeRate(rate: 51.33)) { title, signature in
            completionRateTitle = title
            completionSignatureRequirement = signature
        }

        // When
        viewModel.selectRate()

        // Then
        XCTAssertEqual(completionRateTitle, rate.title)
        XCTAssertEqual(completionSignatureRequirement, .adultSignatureRequired)
    }

}
