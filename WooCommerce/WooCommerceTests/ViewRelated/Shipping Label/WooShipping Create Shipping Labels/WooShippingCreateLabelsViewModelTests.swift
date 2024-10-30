import XCTest
@testable import WooCommerce
@testable import Networking
import WooFoundation

final class WooShippingCreateLabelsViewModelTests: XCTestCase {
    func test_inits_with_expected_values() {
        // Given
        let order = Order.fake()

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order)

        // Then
        XCTAssertFalse(viewModel.markOrderComplete)
        XCTAssertFalse(viewModel.canPurchaseLabel)
        XCTAssertNil(viewModel.totalCost)
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

    func test_onLabelPurchase_notifies_when_order_should_not_be_marked_complete() {
        // Given
        let order = Order.fake()

        // When
        let markOrderComplete: Bool = waitFor { promise in
            let viewModel = WooShippingCreateLabelsViewModel(order: order, onLabelPurchase: { complete in
                promise(complete)
            })
            viewModel.markOrderComplete = false
            viewModel.purchaseLabel()
        }

        // Then
        XCTAssertFalse(markOrderComplete)
    }

    func test_onLabelPurchase_notifies_when_order_should_be_marked_complete() {
        // Given
        let order = Order.fake()

        // When
        let markOrderComplete: Bool = waitFor { promise in
            let viewModel = WooShippingCreateLabelsViewModel(order: order, onLabelPurchase: { complete in
                promise(complete)
            })
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
        let card = try XCTUnwrap(viewModel.shippingService.serviceTabs.first?.cards.first)
        card.selectRate()

        // Then
        XCTAssertTrue(viewModel.canPurchaseLabel)
    }

    func test_selecting_shipping_rate_sets_totalCost() throws {
        // Given
        let order = Order.fake()
        let viewModel = WooShippingCreateLabelsViewModel(order: order, currencySettings: CurrencySettings())

        // When
        let card = try XCTUnwrap(viewModel.shippingService.serviceTabs.first?.cards.first)
        card.selectRate()

        // Then
        XCTAssertEqual(viewModel.totalCost, "$7.53")
    }

    func test_formatAmount_for_standard_shipping_rate_returns_formatted_rate() throws {
        // Given
        let order = Order.fake()
        let viewModel = WooShippingCreateLabelsViewModel(order: order, currencySettings: CurrencySettings())
        let card = try XCTUnwrap(viewModel.shippingService.serviceTabs.first?.cards[1])
        card.selectRate()

        // When
        let selectedRate = try XCTUnwrap(viewModel.shippingService.selectedRate)
        let formattedAmount = viewModel.formatAmount(for: selectedRate.rate)

        // Then
        XCTAssertEqual(formattedAmount, "$40.06")
    }

    func test_formatAmount_for_signature_shipping_rate_returns_formatted_difference_from_base_rate() throws {
        // Given
        let order = Order.fake()
        let viewModel = WooShippingCreateLabelsViewModel(order: order, currencySettings: CurrencySettings())
        let card = try XCTUnwrap(viewModel.shippingService.serviceTabs.first?.cards[1])
        card.signatureRequirement = .signatureRequired
        card.selectRate()

        // When
        let signatureRate = try XCTUnwrap(viewModel.shippingService.selectedRate?.signatureRate)
        let formattedAmount = viewModel.formatAmount(for: signatureRate)

        // Then
        XCTAssertEqual(formattedAmount, "$2.70")
    }

    func test_canViewLabel_true_when_shipping_label_exists() {
        // Given
        let order = Order.fake()
        let label = ShippingLabel.fake()

        // When
        let newLabelViewModel = WooShippingCreateLabelsViewModel(order: order)
        let existingLabelViewModel = WooShippingCreateLabelsViewModel(order: order, shippingLabel: label)

        // Then
        XCTAssertFalse(newLabelViewModel.canViewLabel)
        XCTAssertTrue(existingLabelViewModel.canViewLabel)
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
