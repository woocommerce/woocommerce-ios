import XCTest
@testable import WooCommerce
@testable import Networking
import WooFoundation

final class WooShippingCreateLabelsViewModelTests: XCTestCase {
    func test_inits_with_expected_values_for_shipping_label_creation() {
        // Given
        let order = Order.fake()

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order)

        // Then
        XCTAssertFalse(viewModel.markOrderComplete)
        XCTAssertFalse(viewModel.canPurchaseLabel)
        XCTAssertNil(viewModel.totalCost)
        XCTAssertFalse(viewModel.canViewLabel)
    }

    func test_inits_with_expected_values_for_viewing_purchased_label() {
        // Given
        let order = Order.fake()
        let label = ShippingLabel.fake()

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, shippingLabel: label)

        // Then
        XCTAssertNotNil(viewModel.postPurchase)
        XCTAssertFalse(viewModel.canPurchaseLabel)
        XCTAssertNotNil(viewModel.totalCost)
        XCTAssertTrue(viewModel.canViewLabel)
        XCTAssertEqual(viewModel.shippingRates.count, 1)
    }

    func test_site_address_converted_to_formatted_originAddress() {
        // Given
        let siteSettings = mapLoadGeneralSiteSettingsResponse()
        let siteAddress = SiteAddress(siteSettings: siteSettings)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(), siteAddress: siteAddress)

        // Then
        XCTAssertEqual("60 29th Street #343, Auburn NY 13021, US", viewModel.originAddress)
    }

    func test_order_shipping_address_converted_to_formatted_desinationAddressLines() {
        // Given
        let address = Address.fake().copy(address1: "1 Main Street", city: "San Francisco", state: "CA", postcode: "12345", country: "US")
        let order = Order.fake().copy(shippingAddress: address)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order)

        // Then
        let expectedAddressLines = [address.address1, "\(address.city) \(address.state) \(address.postcode)", address.country]
        XCTAssertEqual(expectedAddressLines, viewModel.destinationAddressLines)
    }

    func test_order_shipping_lines_converted_to_shippingLineViewModels() {
        // Given
        let order = Order.fake().copy(shippingLines: [ShippingLine.fake().copy(shippingID: 1),
                                                      ShippingLine.fake().copy(shippingID: 2),
                                                      ShippingLine.fake().copy(shippingID: 3)])

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order)

        // Then
        XCTAssertEqual(order.shippingLines.map({ $0.shippingID }), viewModel.shippingLines.map({ $0.id }))
    }

    func test_onLabelPurchase_notifies_when_order_should_not_be_marked_complete() throws {
        // Given
        let order = Order.fake()

        // When
        let markOrderComplete: Bool = try waitFor { promise in
            let viewModel = WooShippingCreateLabelsViewModel(order: order, onLabelPurchase: { complete in
                promise(complete)
            })
            try viewModel.selectShippingRate()
            viewModel.markOrderComplete = false
            viewModel.purchaseLabel()
        }

        // Then
        XCTAssertFalse(markOrderComplete)
    }

    func test_onLabelPurchase_notifies_when_order_should_be_marked_complete() throws {
        // Given
        let order = Order.fake()

        // When
        let markOrderComplete: Bool = try waitFor { promise in
            let viewModel = WooShippingCreateLabelsViewModel(order: order, onLabelPurchase: { complete in
                promise(complete)
            })
            try viewModel.selectShippingRate()
            viewModel.markOrderComplete = true
            viewModel.purchaseLabel()
        }

        // Then
        XCTAssertTrue(markOrderComplete)
    }

    func test_canPurchaseLabel_true_after_shipping_rate_is_selected() throws {
        // Given
        let order = Order.fake()
        let viewModel = WooShippingCreateLabelsViewModel(order: order)
        XCTAssertFalse(viewModel.canPurchaseLabel)

        // When
        try viewModel.selectShippingRate()

        // Then
        XCTAssertTrue(viewModel.canPurchaseLabel)
    }

    func test_selecting_shipping_rate_sets_totalCost() throws {
        // Given
        let order = Order.fake()
        let viewModel = WooShippingCreateLabelsViewModel(order: order, currencySettings: CurrencySettings())

        // When
        try viewModel.selectShippingRate()

        // Then
        XCTAssertEqual(viewModel.totalCost, "$7.53")
    }

    func test_selecting_standard_shipping_rate_sets_expected_shippingRates() throws {
        // Given
        let order = Order.fake()
        let viewModel = WooShippingCreateLabelsViewModel(order: order, currencySettings: CurrencySettings())

        // When
        try viewModel.selectShippingRate()

        // Then
        XCTAssertEqual(viewModel.shippingRates.count, 1)
        XCTAssertEqual(viewModel.shippingRates.first?.title, "USPS - Media Mail")
        XCTAssertEqual(viewModel.shippingRates.first?.amount, "$7.53")
    }

    func test_selecting_signature_shipping_rate_sets_expected_shippingRates() throws {
        // Given
        let order = Order.fake()
        let viewModel = WooShippingCreateLabelsViewModel(order: order, currencySettings: CurrencySettings())
        let card = try XCTUnwrap(viewModel.shippingService.serviceTabs.first?.cards[1])
        card.signatureRequirement = .signatureRequired

        // When
        card.selectRate()

        // Then
        XCTAssertEqual(viewModel.shippingRates.count, 2)
        XCTAssertEqual(viewModel.shippingRates[0].title, "USPS - Parcel Select Mail (base fee)")
        XCTAssertEqual(viewModel.shippingRates[0].amount, "$40.06")
        XCTAssertEqual(viewModel.shippingRates[1].title, "Signature Required")
        XCTAssertEqual(viewModel.shippingRates[1].amount, "$2.70")
    }

    func test_selecting_adult_signature_shipping_rate_sets_expected_shippingRates() throws {
        // Given
        let order = Order.fake()
        let viewModel = WooShippingCreateLabelsViewModel(order: order, currencySettings: CurrencySettings())
        let card = try XCTUnwrap(viewModel.shippingService.serviceTabs.first?.cards[1])
        card.signatureRequirement = .adultSignatureRequired

        // When
        card.selectRate()

        // Then
        XCTAssertEqual(viewModel.shippingRates.count, 2)
        XCTAssertEqual(viewModel.shippingRates[0].title, "USPS - Parcel Select Mail (base fee)")
        XCTAssertEqual(viewModel.shippingRates[0].amount, "$40.06")
        XCTAssertEqual(viewModel.shippingRates[1].title, "Adult Signature Required")
        XCTAssertEqual(viewModel.shippingRates[1].amount, "$6.90")
    }
}

private extension WooShippingCreateLabelsViewModelTests {
    /// Returns the SiteSettings output upon receiving `filename` (Data Encoded)
    ///
    func mapGeneralSettings(from filename: String) -> [SiteSetting] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! SiteSettingsMapper(siteID: 123, settingsGroup: SiteSettingGroup.general).map(response: response)
    }

    /// Returns the SiteSetting array as output upon receiving `settings-general`
    ///
    func mapLoadGeneralSiteSettingsResponse() -> [SiteSetting] {
        return mapGeneralSettings(from: "settings-general")
    }
}

private extension WooShippingCreateLabelsViewModel {
    /// Selects the first available shipping rate.
    func selectShippingRate() throws {
        let card = try XCTUnwrap(self.shippingService.serviceTabs.first?.cards.first)
        card.selectRate()
    }
}
