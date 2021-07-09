import XCTest
@testable import WooCommerce
import Yosemite

final class ShippingLabelCarrierRowViewModelTests: XCTestCase {

    func test_properties_returns_expected_values() {
        // Given
        let viewModel = ShippingLabelCarrierRowViewModel(selected: true,
                                                         signatureSelected: true,
                                                         adultSignatureSelected: false,
                                                         rate: MockShippingLabelCarrierRate.makeRate(rate: 40.33),
                                                         signatureRate: MockShippingLabelCarrierRate.makeRate(rate: 45.99),
                                                         adultSignatureRate: MockShippingLabelCarrierRate.makeRate(rate: 51.33),
                                                         currencySettings: CurrencySettings()) { (_, _, _) in
        }

        // Then
        XCTAssertEqual(viewModel.selected, true)
        XCTAssertEqual(viewModel.signatureSelected, true)
        XCTAssertEqual(viewModel.adultSignatureSelected, false)
        XCTAssertEqual(viewModel.title, "USPS - Parcel Select Mail")
        XCTAssertEqual(viewModel.subtitle, "2 business days")
        XCTAssertEqual(viewModel.price, "$45.99")
        XCTAssertEqual(viewModel.carrierLogo, UIImage(named: "shipping-label-usps-logo"))
        XCTAssertEqual(viewModel.extraInfo, "Includes USPS tracking, Eligible for free pickup")
        XCTAssertEqual(viewModel.displaySignatureRequired, true)
        XCTAssertEqual(viewModel.displayAdultSignatureRequired, true)
        XCTAssertEqual(viewModel.signatureRequiredText, "Signature required (+$5.66)")
        XCTAssertEqual(viewModel.adultSignatureRequiredText, "Adult signature required (+$11.00)")
    }

    func test_handleSelection_return_expected_values() throws {
        // Given
        let expectedRate: ShippingLabelCarrierRate = waitFor { promise in
        let viewModel = ShippingLabelCarrierRowViewModel(selected: false,
                                                         signatureSelected: false,
                                                         adultSignatureSelected: false,
                                                         rate: MockShippingLabelCarrierRate.makeRate(rate: 40.33),
                                                         signatureRate: MockShippingLabelCarrierRate.makeRate(rate: 45.99),
                                                         adultSignatureRate: MockShippingLabelCarrierRate.makeRate(rate: 51.33),
                                                         currencySettings: CurrencySettings()) { (rate, _, _) in
            promise(rate)
        }
            // When
            viewModel.handleSelection()
        }



        // Then
        let rate = try XCTUnwrap(expectedRate)
        XCTAssertEqual(rate, MockShippingLabelCarrierRate.makeRate(rate: 40.33))
    }

    func test_handleSignatureSelection_return_expected_values() throws {
        // Given
        let expectedRate: ShippingLabelCarrierRate? = waitFor { promise in
        let viewModel = ShippingLabelCarrierRowViewModel(selected: false,
                                                         signatureSelected: false,
                                                         adultSignatureSelected: false,
                                                         rate: MockShippingLabelCarrierRate.makeRate(rate: 40.33),
                                                         signatureRate: MockShippingLabelCarrierRate.makeRate(rate: 45.99),
                                                         adultSignatureRate: MockShippingLabelCarrierRate.makeRate(rate: 51.33),
                                                         currencySettings: CurrencySettings()) { (rate, signatureRate, _) in
            promise(signatureRate)
        }
            // When
            viewModel.handleSignatureSelection()
        }



        // Then
        let rate = try XCTUnwrap(expectedRate)
        XCTAssertEqual(rate, MockShippingLabelCarrierRate.makeRate(rate: 45.99))
    }

    func test_handleAdultSignatureSelection_return_expected_values() throws {
        // Given
        let expectedRate: ShippingLabelCarrierRate? = waitFor { promise in
        let viewModel = ShippingLabelCarrierRowViewModel(selected: false,
                                                         signatureSelected: false,
                                                         adultSignatureSelected: false,
                                                         rate: MockShippingLabelCarrierRate.makeRate(rate: 40.33),
                                                         signatureRate: MockShippingLabelCarrierRate.makeRate(rate: 45.99),
                                                         adultSignatureRate: MockShippingLabelCarrierRate.makeRate(rate: 51.33),
                                                         currencySettings: CurrencySettings()) { (rate,
                                                                                                                                    _,
                                                                                                                                    adultSignatureRate) in
            promise(adultSignatureRate)
        }
            // When
            viewModel.handleAdultSignatureSelection()
        }



        // Then
        let rate = try XCTUnwrap(expectedRate)
        XCTAssertEqual(rate, MockShippingLabelCarrierRate.makeRate(rate: 51.33))
    }
}
